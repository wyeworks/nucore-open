# frozen_string_literal: true

# UMass specific rake tasks
namespace :umass_corum do
  desc "Generate batch file for open journals and upload for processing"
  task :render_and_move, [:render_dir, :move_dir] => :environment do |_t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::INFO
    PrnRenderer.render(args.render_dir, args.move_dir)
  end
end
