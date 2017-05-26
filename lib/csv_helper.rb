module CSVHelper

  require "csv"

  def set_csv_headers(filename)
    if request.env["HTTP_USER_AGENT"] =~ /msie/i
      headers["Pragma"] = "public"
      headers["Content-type"] = "text/plain"
      headers["Cache-Control"] = "no-cache, must-revalidate, post-check=0, pre-check=0"
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
      headers["Expires"] = "0"
    else
      headers["Content-Type"] ||= "text/csv"
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
    end
  end

end
