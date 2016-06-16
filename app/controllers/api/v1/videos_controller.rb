class Api::V1::VideosController < Api::V1::ApiController
  respond_to :json

  before_action :authenticate_user!, except: [:index]
  before_action :fetch_anime

  # DOC GENERATED AUTOMATICALLY: REMOVE THIS LINE TO PREVENT REGENARATING NEXT TIME
  api :GET, '/animes/:anime_id/videos', 'List videos'
  def index
    @collection = @anime.videos
    respond_with @collection
  end

  # DOC GENERATED AUTOMATICALLY: REMOVE THIS LINE TO PREVENT REGENARATING NEXT TIME
  api :POST, '/animes/:anime_id/videos', 'Create a video'
  param :video, Hash do
    param :kind, %w(PV OP ED), required: true
    param :name, String, required: false
    param :url, String, required: true
  end
  def create
    @resource, @version = versioneer.upload video_params, current_user
    @resource = Video.find_by url: @resource.url if duplicate? @resource
    respond_with @resource
  end

  # DOC GENERATED AUTOMATICALLY: REMOVE THIS LINE TO PREVENT REGENARATING NEXT TIME
  api :DELETE, '/animes/:anime_id/videos/:id', 'Destroy a video'
  def destroy
    @version = versioneer.delete params[:id], current_user
    head 200
  end

private

  def video_params
    params
      .require(:video)
      .permit(:url, :kind, :name)
      .merge(uploader_id: current_user.id)
  end

  def versioneer
    Versioneers::VideosVersioneer.new @anime
  end

  def duplicate? video
    video.errors.one? &&
      video.errors[:url] == Array(I18n.t('activerecord.errors.messages.taken'))
  end

  def fetch_anime
    @anime = Anime.find_by(
      id: CopyrightedIds.instance.restore(params[:anime_id], 'anime')
    )&.decorate
  end
end