class AnimeOnlineDomain
  HOSTS = ['0.0.0.0', 'animeonline.dev', 'animeonline.production']

  def self.matches? request
    HOSTS.include? request.host
  end
end
