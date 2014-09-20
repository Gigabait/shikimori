class AniMangaDecorator < DbEntryDecorator
  include AniMangaDecorator::UrlHelpers
  include AniMangaDecorator::SeoHelpers

  TopicsPerPage = 4
  NewsPerPage = 12
  VISIBLE_RELATED = 7

  instance_cache :topics, :news, :reviews, :reviews_count, :comment_reviews_count,
    :is_favoured, :favoured, :rate, :changes, :roles, :related, :cosplay,
    :friend_rates, :recent_rates, :chronology,
    :preview_reviews_thread, :main_reviews_thread

  # топики
  def topics
    object
      .topics
      .wo_generated
      .includes(:section)
      .limit(TopicsPerPage)
      .map { |topic| format_menu_topic topic, :updated_at }
  end

  # новости
  def news
    object
      .news
      .includes(:section)
      .limit(NewsPerPage)
      .map { |topic| format_menu_topic topic, :created_at }
  end

  # число обзоров
  def reviews_count
    object.reviews.visible.count
  end

  # есть ли обзоры
  def reviews?
    reviews_count > 0
  end

  # добавлено ли в избранное?
  def favoured?
    h.user_signed_in? && h.current_user.favoured?(object)
  end

  # добавившие в избранное
  def favoured
    FavouritesQuery.new.favoured_by object, 12
  end

  # добавлено ли в список текущего пользователя?
  def rate
    rates.where(user_id: h.current_user.id).decorate.first if h.user_signed_in?
  end

  # основной топик
  def preview_reviews_thread
    thread = TopicDecorator.new object.thread
    thread.reviews_only! if comment_reviews?
    thread.preview_mode!
    thread
  end

  # полный топик отзывов
  def main_reviews_thread
    thread = TopicDecorator.new object.thread
    thread.reviews_only!
    thread.topic_mode!
    thread
  end

  # презентер пользовательских изменений
  def changes
    ChangesDecorator.new object
  end

  # объект с ролями аниме
  def roles
    RolesDecorator.new object
  end

  # презентер связанных аниме
  def related
    RelatedDecorator.new object
  end

  # объект с косплеем
  def cosplay
    CosplayDecorator.new object
  end

  # число коментариев
  def comments_count
    thread.comments_count
  end

  # число отзывов
  def comment_reviews_count
    object.thread.comments.reviews.count
  end

  # есть ли отзывы?
  def comment_reviews?
    @comment_reviews ||= comment_reviews_count > 0
  end

  # есть ли хоть какая-то статистика тут?
  def with_stats?
    (object.mal_scores || object.ani_db_scores || object.world_art_scores) && (object.mal_scores && object.mal_scores.sum != 0)
  end

  # оценки друзей
  def friend_rates
    if h.user_signed_in?
      UserRatesQuery.new(object, h.current_user).friend_rates
    else
      []
    end
  end

  # последние изменения от других пользователей
  def recent_rates limit
    UserRatesQuery.new(object, h.current_user).recent_rates limit
  end

  # полная хронология аниме
  def chronology
    ChronologyQuery.new(object, true).fetch.map(&:decorate)
  end

  # показывать ли блок файлов
  def files?
    h.user_signed_in? && anime? && !anons? && display_sensitive?
  end

  # показывать ли ссылки, если аниме или манга для взрослых?
  def display_sensitive?
    !object.censored? ||
      (h.user_signed_in? && h.current_user.created_at < DateTime.now - 6.months)
  end

  # есть ли видео для просмотра онлайн?
  def anime_videos?
    object.respond_to?(:anime_videos) && object.anime_videos.worked.any?
  end

  # тип элемента для schema.org
  def itemtype
    if kind == 'Movie'
      'http://schema.org/Movie'
    elsif kind == 'TV'
      'http://schema.org/TVSeries'
    else
      'http://schema.org/CreativeWork'
    end
  end

private
  def format_menu_topic topic, order
    {
      date: h.time_ago_in_words(topic.send(order), "%s назад"),
      id: topic.id,
      name: topic.to_s,
      title: topic.title,
      tooltip: topic.action == AnimeHistoryAction::Episode,
      url: h.topic_url(topic)
    }
  end
end
