# frozen_string_literal: true

require "rails_helper"

RSpec.describe FlashHtmlSafe do
  let(:flash) { ActionDispatch::Flash::FlashHash.new }
  let(:restored_flash) do
    session_value = JSON.parse(flash.to_session_value.to_json)
    ActionDispatch::Flash::FlashHash.from_session_value(session_value)
  end

  it "keeps html_safe messages html_safe after a JSON round-trip", :aggregate_failures do
    flash[:notice] = "First<br>Can&rsquo;t".html_safe

    expect(restored_flash[:notice]).to eq("First<br>Can&rsquo;t")
    expect(restored_flash[:notice]).to be_html_safe
  end

  it "does not mark plain messages as html_safe", :aggregate_failures do
    flash[:notice] = "First<br>Second".html_safe
    flash[:error] = "<a href=\"/\">Testing</a>"

    expect(restored_flash[:notice]).to be_html_safe
    expect(restored_flash[:error]).not_to be_html_safe
  end

  it "does not store the marker when no message is html_safe" do
    flash[:error] = "Plain message"

    expect(flash.to_session_value).to eq("discard" => [], "flashes" => { "error" => "Plain message" })
  end

  it "still discards the restored messages after they are used" do
    flash[:notice] = "First<br>Second".html_safe

    expect(restored_flash.to_session_value).to be_nil
  end

  it "ignores a session written without the marker" do
    restored = ActionDispatch::Flash::FlashHash.from_session_value("discard" => [], "flashes" => { "notice" => "<b>Old</b>" })

    expect(restored[:notice]).not_to be_html_safe
  end
end
