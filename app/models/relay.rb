require "net/http"

class Relay < ActiveRecord::Base
  belongs_to :instrument

  validates_presence_of :instrument_id, :on => :update
  validates_uniqueness_of :port, :scope => :ip, :allow_blank => true

  attr_accessible :type, :username, :password, :ip, :port, :auto_logout, :instrument_id

  alias_attribute :host, :ip


  CONTROL_MECHANISMS = {
    manual: nil,
    timer: 'timer',
    relay: 'relay'
  }


  def get_status
    query_status
  end

  def activate
    toggle(true)
  end

  def deactivate
    toggle(false)
  end

  def control_mechanism
    CONTROL_MECHANISMS[:manual]
  end

  private

  def toggle(status)
    raise NotImplementedError.new('Subclass must define')
  end

  def query_status
    raise NotImplementedError.new('Subclass must define')
  end
end
