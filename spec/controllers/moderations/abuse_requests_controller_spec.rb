describe Moderations::AbuseRequestsController do
  include_context :authenticated, :forum_moderator

  describe '#index' do
    before { get :index }
    it { expect(response).to have_http_status :success }
  end

  describe '#show' do
    let(:abuse_request) { create :abuse_request }

    describe 'html' do
      before { get :show, params: { id: abuse_request.id } }
      it { expect(response).to have_http_status :success }
    end

    describe 'json' do
      before { get :show, params: { id: abuse_request.id }, format: :json }
      it { expect(response).to have_http_status :success }
    end
  end


  [:summary, :offtopic, :abuse, :spoiler].each do |method|
    describe method.to_s do
      let(:comment) { create :comment }

      describe 'response' do
        before do
          post method,
            params: {
              comment_id: comment.id,
              reason: 'zxcv'
            },
            format: :json
        end

        it do
          expect(response.content_type).to eq 'application/json'
          expect(response).to have_http_status :success
        end
      end

      describe 'result' do
        after { post method, params: { comment_id: comment.id }, format: :json }
        it { expect_any_instance_of(AbuseRequestsService).to receive method }
      end
    end
  end
end
