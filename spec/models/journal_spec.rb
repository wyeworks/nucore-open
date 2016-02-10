require "rails_helper"
require "journal"

RSpec.describe Journal do
  subject(:journal) do
    build(:journal,
      facility: facility,
      created_by: 1,
      journal_date: journal_date,
    )
  end

  let(:facility) { create(:facility) }
  let(:facility_account) { facility.facility_accounts.create(attributes_for(:facility_account)) }
  let(:journal_date) { Time.zone.now }
  let(:order) { create(:purchased_order, product: product) }
  let(:product) { create(:setup_item, facility: facility, facility_account: facility_account) }

  context "#amount" do
    context "when its order detail quantities change" do
      let(:order_details) { order.order_details }

      before :each do
        order_details.each(&:to_complete!)
        journal.save!
        journal.create_journal_rows!(order_details)
      end

      it "updates its total" do
        expect { journal.order_details.first.increment!(:quantity) }
          .to change { journal.reload.amount }.from(1).to(2)
      end
    end
  end

  describe "#submittable?" do
    context "when is_successful is true" do
      before { journal.is_successful = true }

      context "when not reconciled" do
        before { allow(journal).to receive(:reconciled?).and_return(false) }

        it { expect(journal).to be_submittable }
      end

      context "when reconciled" do
        before { allow(journal).to receive(:reconciled?).and_return(true) }

        it { expect(journal).not_to be_submittable }
      end
    end

    context "when is_successful is false" do
      before { journal.is_successful = false }

      context "when not reconciled" do
        before { allow(journal).to receive(:reconciled?).and_return(false) }

        it { expect(journal).not_to be_submittable }
      end

      context "when reconciled" do
        before { allow(journal).to receive(:reconciled?).and_return(true) }

        it { expect(journal).not_to be_submittable }
      end
    end
  end

  describe "#successful?" do
    context "when is_successful is true" do
      before { journal.is_successful = true }

      it { expect(journal).to be_successful }
    end

    context "when is_successful is false" do
      before { journal.is_successful = false }

      it { expect(journal).not_to be_successful }
    end

    context "when is_successful is nil" do
      before { journal.is_successful = nil }

      it { expect(journal).not_to be_successful }
    end
  end

  context "with valid attributes" do
    it "can be created" do
      expect(journal).to be_valid
      journal.save
      expect(journal.id).to be_present
    end
  end

  context "with a journal_date in the future" do
    let(:journal_date) { 1.year.from_now }

    it "is invalid" do
      expect(journal).not_to be_valid
      expect(journal.errors[:journal_date]).to eq ["may not be in the future."]
    end
  end

  context "when journal_date is missing" do
    let(:journal_date) { nil }

    it "is invalid" do
      expect(journal).not_to be_valid
      expect(journal.errors[:journal_date].to_s).to match /may not be blank/
    end
  end

  describe "cutoff date validations", :timecop_freeze do
    let(:now) { Time.zone.parse("2016-02-03") }

    context "no cutoff dates" do
      let(:journal_date) { Time.zone.parse("2013-03-04") }
      it { is_expected.to be_valid }
    end

    context "before this month's cutoff" do
      let!(:cutoff) { JournalCutoffDate.create(cutoff_date: Time.zone.parse("2016-02-04")) }
      let!(:last_cutoff) { JournalCutoffDate.create(cutoff_date: Time.zone.parse("2016-01-04 16:45")) }

      describe "cannot journal before the last month" do
        let(:journal_date) { Time.zone.parse("2016-12-30") }
        it { is_expected.not_to be_valid }
      end

      describe "can journal last month" do
        let(:journal_date) { Time.zone.parse("2016-01-15") }
        it { is_expected.to be_valid }
      end

      describe "can journal this month (before now)" do
        let(:journal_date) { Time.zone.parse("2016-02-02") }
        it { is_expected.to be_valid }
      end
    end

    context "after this month's cutoff" do
      let!(:cutoff) { JournalCutoffDate.create(cutoff_date: Time.zone.parse("2016-02-02")) }

      describe "cannot journal last month" do
        let(:journal_date) { Time.zone.parse("2016-01-15") }
        it { is_expected.not_to be_valid }
      end

      describe "can journal this month (before now)" do
        let(:journal_date) { Time.zone.parse("2016-02-02") }
        it { is_expected.to be_valid }
      end
    end

    context "on the day of the cutoff" do
      let!(:cutoff) { JournalCutoffDate.create(cutoff_date: Time.zone.parse("2016-02-04 16:45")) }
      let(:journal_date) { Time.zone.parse("2016-01-15") }

      describe "before the cutoff" do
        let(:now) { Time.zone.parse("2016-02-04 15:45") }
        it { is_expected.to be_valid }
      end

      describe "after the cutoff" do
        let(:now) { Time.zone.parse("2016-02-04 17:00") }
        it { is_expected.not_to be_valid }
      end
    end
  end

  context "journal creation" do
    before :each do
      @admin = FactoryGirl.create(:user)
      @facilitya = FactoryGirl.create(:facility, :abbreviation => "A")
      @facilityb = FactoryGirl.create(:facility, :abbreviation => "B")
      @facilityc = FactoryGirl.create(:facility, :abbreviation => "C")
      @facilityd = FactoryGirl.create(:facility, :abbreviation => "D")
      @account = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @admin), :facility_id => @facilitya.id)

      # little helper to create the calls which the controller performs
      def create_pending_journal_for(*facilities_list)
        @ods = []

        facilities_list.each do |f|
          od = place_and_complete_item_order(@admin, f, @account, true)
          define_open_account(@item.account, @account.account_number)

          @ods << od
        end

        journal = Journal.create!(
          :facility_id => (facilities_list.size == 1 ? facilities_list.first.id : nil),
          :created_by => @admin.id,
          :journal_date => Time.zone.now
        )

        journal.create_journal_rows!(@ods)

        journal
      end
    end

    context "(with pending journal for A)" do
      before :each do
        create_pending_journal_for(@facilitya)
      end

      it "should not allow creation of a journal for A" do
        expect { create_pending_journal_for( @facilitya) }.to raise_error(Journal::CreationError)
      end
    end

    context "(with: pending journal for A & B)" do
      before :each do
        create_pending_journal_for( @facilitya, @facilityb )
      end

      it "should not allow creation of a journal for B & C (journal pending on B)" do
        expect { create_pending_journal_for( @facilityb, @facilityc ) }.to raise_error(Journal::CreationError)
      end

      it "should not allow creation of a journal for A (journal pending on A)" do
        expect { create_pending_journal_for( @facilitya ) }.to raise_error(Journal::CreationError)
      end

      it "should not allow creation of a journal for B (journal pending on B)" do
        expect { create_pending_journal_for( @facilityb ) }.to raise_error(Journal::CreationError)
      end

      it "should allow creation of a journal for C" do
        expect { create_pending_journal_for( @facilityc ) }.to_not raise_error
      end

      it "should allow creation of a journal for C & D (no journals on either C or D)" do
        expect { create_pending_journal_for( @facilityc, @facilityd ) }.to_not raise_error
      end
    end
  end

  it "requires reference on update" do
    assert journal.save
    assert !journal.save
    expect(journal.errors[:reference]).not_to be_nil

    journal.reference = '12345'
    journal.valid?
    expect(journal.errors[:reference]).to be_empty
  end

  it "requires updated_by on update" do
    assert journal.save
    assert !journal.save
    expect(journal.errors[:updated_by]).not_to be_nil

    journal.updated_by = '1'
    journal.valid?
    expect(journal.errors[:updated_by]).to be_empty
  end

  it "requires a boolean value for is_successful on update" do
    assert journal.save
    assert !journal.save
    expect(journal.errors[:is_successful]).not_to be_nil

    journal.is_successful = true
    journal.valid?
    expect(journal.errors[:is_successful]).to be_empty

    journal.is_successful = false
    journal.valid?
    expect(journal.errors[:is_successful]).to be_empty
  end

  it "should create and attach journal spreadsheet" do
    journal.valid?
    # create nufs account
    @owner    = FactoryGirl.create(:user)
    @account  = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @owner))
    journal.create_spreadsheet
    expect(journal.file.url).to match(/^\/files/)
  end

  it 'should be open' do
    journal.is_successful = nil
    expect(journal).to be_open
  end

  it 'should not be open' do
    journal.is_successful = true
    expect(journal).not_to be_open
  end

  context 'order_details_span_fiscal_years?' do
    before :each do
      Settings.financial.fiscal_year_begins = '06-01'
      @owner    = FactoryGirl.create(:user)
      @account  = FactoryGirl.create(:nufs_account, :account_users_attributes => [ FactoryGirl.attributes_for(:account_user, :user => @owner) ])
      @facility_account = facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @item = facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
      @price_group = FactoryGirl.create(:price_group, :facility => facility)
      FactoryGirl.create(:user_price_group_member, :user => @owner, :price_group => @price_group)
      @pp = @item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :price_group_id => @price_group.id))

      # Create one order detail fulfulled in each month for a two year range
      d1 = Time.zone.parse('2020-01-01')
      @order_details = []
      (0..23).each do |i|
        order=@owner.orders.create(FactoryGirl.attributes_for(:order, :created_by => @owner.id))
        od = order.order_details.create(FactoryGirl.attributes_for(:order_detail, :product => @item))
        od.update_attributes(:actual_cost => 20, :actual_subsidy => 0)
        od.to_complete!
        od.update_attributes(:fulfilled_at => d1 + i.months)
        @order_details << od
      end
      expect(@order_details.size).to eq(24)
      # You can use this to view the indexes
      # @order_details.each_with_index do |od, i|
      #   puts "#{i} #{od.fulfilled_at}"
      # end
    end

    it 'should not span fiscal years with everything in the same year' do
      expect(journal.order_details_span_fiscal_years?(@order_details[5..16])).to be false
    end

    it 'should span fiscal years when it goes over the beginning' do
      expect(journal.order_details_span_fiscal_years?([@order_details[6], @order_details[5], @order_details[4]])).to be true
    end

    it 'should span fiscal years when it goes over the end' do
      expect(journal.order_details_span_fiscal_years?(@order_details[16..17])).to be true
    end

    it 'should return false with just one order detail' do
      journal.order_details_span_fiscal_years?([@order_details[3]])
    end
  end
end
