class ProductDisplayGroup < ApplicationRecord

  belongs_to :facility
  has_many :product_display_group_products, -> { sorted }, inverse_of: :product_display_group, dependent: :destroy
  has_many :products, through: :product_display_group_products, validate: false

  validates :name, presence: true

  before_create :set_default_positions

  scope :sorted, -> { order(:position) }

  def to_s
    name
  end

  Fake = Struct.new(:name, :products, keyword_init: true) do
    def to_s
      name
    end
  end

  def self.fake_groups_by_type(products)
    Product.orderable_types.map do |type|
      Fake.new(name: type.constantize.model_name.human(count: :many), products: products.where(type: type))
    end
  end

  def set_default_positions
    self.position ||= facility.product_display_groups.maximum(:position).to_i + 1
  end

  def associated_errors
    product_display_group_products.select { |join| join.errors.present? }.map(&:errors)
  end

end
