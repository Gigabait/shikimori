class Achievements::Track
  include Sidekiq::Worker

  sidekiq_options(
    queue: :achievements,
    dead: false
  )
  sidekiq_retry_in { 60 * 60 * 24 }

  MUTEX_OPTIONS = { block: 10, expire: 10 }

  def perform user_id, user_rate_id, action
    user = User.find user_id

    Retryable.retryable tries: 2, on: RedisMutex::LockError, sleep: 1 do
      RedisMutex.with_lock("neko_#{user_id}", MUTEX_OPTIONS) do
        neko_update user, user_rate_id, action
      end
    end
  end

private

  def neko_update user, user_rate_id, action
    Neko::Update.call user,
      user_rate_id: user_rate_id,
      action: Types::Neko::Action[action]
  end
end
