module UmassCorum

  class JournalDefinition

    Column = Struct.new(:name, :width, :options) do
    end

    HEADER = [
      Column.new(:trans_code, 3),
      Column.new(:um_batch_id, 6),
      Column.new(:batch_date, 8, type: :date),
      Column.new(:batch_desc, 15),
      Column.new(:jml_type, 1, type: :blank),
      Column.new(:batch_user_code, 2, type: :blank),
      Column.new(:batch_trans_count, 5, type: :integer),
      Column.new(:batch_trans_amount, 11, type: :decimal),
      Column.new(:batch_susp_id, 3, type: :blank),
      Column.new(:batch_originator, 8),
      Column.new(:batch_bank_no, 2, type: :blank),
      Column.new(:batch_hold_flag, 1, type: :blank),
      Column.new(:batch_fas_feed_flag, 1, type: :blank),
      Column.new(:batch_vchr_feed_flag, 1, type: :blank),
      Column.new(:batch_acpt_out_of_ba, 1, type: :blank),
      Column.new(:batch_acctg_feed_ind, 1, type: :blank),
      Column.new(:field18, 18, type: :blank),
      Column.new(:batch_special_process, 3, type: :blank),
      Column.new(:batch_fy, 2, type: :blank),
      Column.new(:batch_business_unit, 5)
    ]

    BODY = [
      Column.new(:trans_code, 3, type: :blank),
      Column.new(:speedtype, 6),
      Column.new(:account, 6),
      Column.new(:trans_ref, 7),
      Column.new(:trans_date, 8, type: :date),
      Column.new(:trans_desc, 20),
      Column.new(:amount, 11, type: :decimal),
      Column.new(:credit_debit, 1),
      Column.new(:trans_2nd_ref, 7),
      Column.new(:trans_id, 11),
      Column.new(:campus_business_unit, 5),
      Column.new(:trans_3rd_ref, 7),
      Column.new(:name, 20),
      Column.new(:doc_reference, 9),
      Column.new(:fund_code, 5),
      Column.new(:department_id, 10),
      Column.new(:program_code, 5),
      Column.new(:class_code, 5),
      Column.new(:project_id, 15),
    ]
  end

end
