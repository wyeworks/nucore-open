class AddUmassJournalFields < ActiveRecord::Migration[5.0]
  def change
    change_table :journal_rows do |t|
      t.string :business_unit, length: 5, null: false, default: "UMAMH"
      t.string :speed_type, length: 6
      t.string :fund, length: 5
      t.string :dept_id, length: 10
      t.string :program, length: 5
      t.string :clazz, length: 5
      t.string :project, length: 15
      t.string :trans_ref, length: 7
      t.string :name_reference, length: 20
      t.datetime :trans_date
      t.string :doc_ref, length: 9
      t.string :ref_2, length: 7
    end
  end
end
