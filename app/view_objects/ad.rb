# rubocop:disable ClassLength
class Ad < ViewObjectBase
  # present advertur blocks
  # block_1: [92_129, 2_731],
  # block_2: [92_445, 1_256],
  # block_3: [92_485, nil]

  BANNERS = {
    istari_x300: {
      provider: Types::Ad::Provider[:istari],
      cookie_id: 'i1_1',
      url: 'https://vk.com/istaricomics',
      src: '/assets/globals/events/i1_1.jpg',
      src_2x: '/assets/globals/events/i1_1@2x.jpg'
    },
    istari_x1170: {
      provider: Types::Ad::Provider[:istari],
      cookie_id: 'i1_2',
      url: 'https://vk.com/istaricomics',
      src: '/assets/globals/events/i1_2.jpg',
      src_2x: '/assets/globals/events/i1_2@2x.jpg'
    },
    advrtr_x728: {
      provider: Types::Ad::Provider[:advertur],
      advertur_id: 1_256,
      width: 728,
      height: 90
    },
    advrtr_x240: {
      provider: Types::Ad::Provider[:advertur],
      advertur_id: 2_731,
      width: 240,
      height: 400
    },
    yd_poster_x300_2x: {
      provider: Types::Ad::Provider[:yandex_direct],
      yandex_id: 'R-A-227837-4'
    },
    yd_poster_x240_2x: {
      provider: Types::Ad::Provider[:yandex_direct],
      yandex_id: 'R-A-227837-5'
    },
    yd_rtb_x240: {
      provider: Types::Ad::Provider[:yandex_direct],
      yandex_id: 'R-A-227837-2'
    },
    yd_horizontal: {
      provider: Types::Ad::Provider[:yandex_direct],
      yandex_id: 'R-A-227837-7'
    },
    yd_wo_fallback: {
      provider: Types::Ad::Provider[:yandex_direct],
      yandex_id: nil
    }
  }
  FALLBACKS = {
    yd_poster_x300_2x: :advrtr_x240,
    yd_poster_x240_2x: :advrtr_x240,
    yd_rtb_x240: :advrtr_x240,
    yd_horizontal: :advrtr_x728
  }
  ISTARI_CONTROLLER_KEY = :"@is_istari_shown"

  attr_reader :banner_type, :policy
  delegate :allowed?, to: :policy

  def initialize banner_type
    switch_banner banner_type

    switch_banner :yd_poster_x300_2x if yd_rtb_in_topics?
    switch_banner :yd_poster_x240_2x if yd_x300_body_x1000?
    switch_banner FALLBACKS[banner_type] if not_allowed_with_fallback?
  end

  # def allowed?
    # # temporarily disable advertur
    # if provider == Types::Ad::Provider[:advertur] &&
        # h.params[:action] != 'advertur_test' && Rails.env.production? &&
        # h.current_user&.id != 1
      # return false
    # end
    # policy.allowed?
  # end

  def provider
    banner[:provider]
  end

  def ad_params
    return unless yandex_direct?

    {
      blockId: banner[:yandex_id],
      renderTo: @banner_type,
      async: true
    }
  end

  def css_class
    # if yandex_direct?
      # "spnsrs_#{@banner_type}"
    # else
      # "spnsrs_#{@banner_type}_#{banner[:width]}x#{banner[:height]}"
    # end

    "spnsrs_#{@banner_type}"
  end

  def to_html
    finalize if istari?

    <<-HTML.gsub(/\n|^\ +/, '')
      <div class="b-spnsrs-#{@banner_type}">
        <center>
          #{ad_html}
        </center>
      </div>
    HTML
  end

private

  def switch_banner banner_type
    @banner_type = banner_type
    @policy = build_policy
  end

  def build_policy
    AdsPolicy.new(
      is_ru_host: h.ru_host?,
      is_shikimori: h.shikimori?,
      ad_provider: provider,
      user_id: h.current_user&.id,
      is_istari_shown: h.controller.instance_variable_get('@is_istari_shown')
    )
  end

  def banner
    BANNERS[@banner_type]
  end

  def yandex_direct?
    provider == Types::Ad::Provider[:yandex_direct]
  end

  def istari?
    provider == Types::Ad::Provider[:istari]
  end

  def ad_html
    if yandex_direct?
      "<div id='#{@banner_type}'></div>"
    elsif istari?
      "<a href='#{banner[:url]}'>"\
        "<img src='#{banner[:src]}' srcset='#{banner[:src_2x]} 2x'></a>"
    else
      "<iframe src='#{advertur_url}' width='#{banner[:width]}px' "\
        "height='#{banner[:height]}px'>"
    end
  end

  def advertur_url
    h.spnsr_url(
      banner[:advertur_id],
      width: banner[:width],
      height: banner[:height],
      container_class: css_class,
      protocol: false
    )
  end

  def yd_rtb_in_topics?
    @banner_type == :yd_rtb_x240 && h.params[:controller] == 'topics'
  end

  def yd_x300_body_x1000?
    @banner_type == :yd_poster_x300_2x &&
      h.current_user&.preferences&.body_width_x1000?
  end

  def not_allowed_with_fallback?
    !@policy.allowed? && FALLBACKS[@banner_type]
  end

  def finalize
    h.controller.instance_variable_set ISTARI_CONTROLLER_KEY, true
  end
end
# rubocop:enable ClassLength
