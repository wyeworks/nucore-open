# frozen_string_literal: true

class DropSurveyor < ActiveRecord::Migration[4.2]

  def self.up
    drop_table :answers
    drop_table :dependencies
    drop_table :dependency_conditions
    drop_table :question_groups
    drop_table :questions
    drop_table :response_sets
    drop_table :responses
    drop_table :surveys
    drop_table :survey_sections
    drop_table :validations
    drop_table :validation_conditions
    drop_table :service_surveys
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
