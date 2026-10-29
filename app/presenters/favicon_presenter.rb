# frozen_string_literal: true

class FaviconPresenter
  def self.favicons
    return @favicons if defined?(@favicons)
    pngs = Dir.glob("app/assets/images/favicons/*.png").map do |png|
      rel = png.include?("apple-touch-icon") ? "apple-touch-icon" : "shortcut icon"
      { path: "favicons/" + File.basename(png), rel: rel, type: "image/png" }
    end
    svgs = Dir.glob("app/assets/images/favicons/*.svg").map do |svg|
      { path: "favicons/" + File.basename(svg), rel: "shortcut icon", type: "image/svg" }
    end
    @favicons = pngs + svgs
  end
end
