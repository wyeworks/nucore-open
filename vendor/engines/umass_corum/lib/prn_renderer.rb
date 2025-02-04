# frozen_string_literal: true

class PrnRenderer

  attr_reader :from_dir, :to_dir, :date

  UPLOAD_FILENAME = "A100.UMGL7056.IAL.INPUT"

  def initialize(from_dir, to_dir = nil, date = Date.today)
    # /home/corum/files/FTP-out/temp
    @from_dir = create_dir(from_dir)
    # /home/corum/files/FTP-out/current
    @to_dir = create_dir(to_dir)
    @date = date # handy for debugging
  end

  def self.render(from_dir, to_dir = nil)
    new(from_dir, to_dir).render
  end

  def render
    raise ArgumentError, "Must specify a directory to render in" unless from_dir
    # The UMass-run file watcher script takes a break on Sat/Sun
    return if date.on_weekend?

    render!
  end

  def render!
    return if journals.empty?

    batch_file_name = "#{today.delete('-')}_#{UPLOAD_FILENAME}"
    batch_file_src = File.join(from_dir, batch_file_name)

    File.open(batch_file_src, "w") do |prn_file|
      journals.each do |journal|
        add_journal_to_file(prn_file, journal)
      end
    end

    FileUtils.mv batch_file_src, File.join(to_dir, batch_file_name) if to_dir
  end

  def create_dir(path)
    FileUtils.mkdir_p(path) if path.present? && !Dir.exist?(path)
    path
  end

  private

  def journals
    return @journals if @journals

    window_start = window_end = Time.zone.parse("#{today} 17:00:00")

    begin
      window_start -= 1.day
    end while window_start.on_weekend?

    @journals = Journal.where("created_at >= ? AND created_at < ? AND is_successful IS NULL", window_start, window_end).all
  end

  def add_journal_to_file(prn_file, journal)
    journal_prn = UmassCorum::Journals::JournalPrn.new(journal)
    prn_file.puts(journal_prn.render(batch: true))
  end

  def today
    date.to_s
  end

end
