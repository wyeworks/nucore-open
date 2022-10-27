# frozen_string_literal: true

class StoredFileZipper

  attr_reader :files

  def initialize(files)
    @files = files
  end

  def read
    return @read if @read
    zip_io = build_zip
    zip_io.rewind
    @read = zip_io.read
  end

  private

  def build_zip
    @filenames = {}

    Zip::OutputStream.write_buffer do |stream|
      files.each do |file|
        stream.put_next_entry(filename(file))
        stream << file.read_attached_file
      end
    end
  end

  # If a filename has already been used, append a -X to the end of the name
  # before the extension. E.g. 12345_B07.ab1 => 12345_B07-1.ab1
  def filename(file)
    if @filenames.key?(file.name)
      @filenames[file.name] += 1
      file.name.sub(/\.(\w+)\z/, "-#{@filenames[file.name]}.\\1")
    else
      @filenames[file.name] = 0
      file.name
    end
  end

end
