class AddOrganizationIdToOffers < ActiveRecord::Migration
  class Offer < ActiveRecord::Base
    attr_accessor :umbrella, :classification
    belongs_to :location
  end

  def up
    add_column :offers, :organization_id, :integer
debugger
    Offer.find_each do |offer|
      offer.update_column :organization_id, offer.location.organization.id
    end

    change_column :offers, :organization_id, :integer, null: false
  end

  def down
    remove_column :offers, :organization_id
  end
end