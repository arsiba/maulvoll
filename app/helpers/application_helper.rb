module ApplicationHelper
  def qr_code(url)
    RQRCode::QRCode.new(url).as_svg(module_size: 4, standalone: true, use_path: true).html_safe
  end

  def score(value)
    value.nil? ? "–" : number_with_precision(value, precision: 1)
  end
end
