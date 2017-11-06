class BbCodes::Text
  method_object :text

  # TODO:
  # delete CommentHelper
  # delete BB_CODE_REPLACERS
  # delete include Rails.application.routes.url_helpers
  include CommentHelper
  BB_CODE_REPLACERS = COMPLEX_BB_CODES.map { |v| "#{v}_to_html".to_sym }.reverse
  include Rails.application.routes.url_helpers

  HASH_TAGS = BbCodes::ToTag.call %i[image img]

  TAGS = BbCodes::ToTag.call %i[
    quote replies comment
    db_entry_url video_url video
    poster wall_image entries
    wall poll

    contest_status contest_round_status
    html5_video source broadcast

    div hr br p
    b i u s
    size center right
    color solid url
    list h3
  ]

  DB_ENTRY_BB_CODES = %i[anime manga ranobe character person]
  DB_ENTRY_TAGS = BbCodes::ToTag.call DB_ENTRY_BB_CODES

  OBSOLETE_TAGS = %r{\[user_change=\d+\] | \[/user_change\]}mix

  MALWARE_DOMAINS = %r{(https?://)? (images.webpark.ru|shikme.ru) }mix

  default_url_options[:protocol] = false
  default_url_options[:host] ||=
    if Rails.env.development?
      'shikimori.dev'
    elsif Rails.env.beta?
      "beta.#{Shikimori::DOMAIN}"
    else
      Shikimori::DOMAIN
    end

  def call
    text = (@text || '').fix_encoding.strip
    text = strip_malware text
    text = BbCodes::UserMention.call text

    text = String.new ERB::Util.h(text)
    text = bb_codes text

    BbCodes::CleanupHtml.call text
  end

  # обработка ббкодов текста
  # TODO: перенести весь код ббкодов сюда или в связанные классы
  def bb_codes text
    text_hash = XXhash.xxh32 text, 0

    code_tag = BbCodes::Tags::CodeTag.new(text)
    text = code_tag.preprocess
    text = text.gsub /\r\n|\r/, "\n"
    text = BbCodes::Tags::CleanupNewLines.call text, BbCodes::Tags::CleanupNewLines::TAGS

    HASH_TAGS.each do |tag_klass|
      text = tag_klass.instance.format text, text_hash
    end

    TAGS.each do |tag_klass|
      text = tag_klass.instance.format text
    end

    BB_CODE_REPLACERS.each do |processor|
      text = send processor, text
    end

    text = text.gsub OBSOLETE_TAGS, ''
    text = BbCodes::DbEntryMention.call text

    DB_ENTRY_TAGS.each do |tag_klass|
      text = tag_klass.instance.format text
    end

    text = text.gsub /\r\n|\r|\n/, '<br>'
    text = code_tag.postprocess text
    text
  end

  # удаление из текста вредоносных доменов
  def strip_malware text
    text.gsub MALWARE_DOMAINS, 'malware.domain'
  end
end