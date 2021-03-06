class OffersController < ApplicationController
  include GmapsVariable
  respond_to :html

  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    build_search_cache_and_search params[:page]
    assign_search_result_instance_variables
    test_location_unavailable
    set_position
    prepare_gmaps_variables @personal_offers if @personal_offers
    respond_to do |format|
      format.html do
        template = request.xhr? ? :index_xhr : :index
        render template, layout: !request.xhr?
      end
    end
  end

  rescue_from InvalidLocationError do |_error|
    render 'invalid_location', status: 404
  end

  def show
    @offer = Offer.friendly.find(params[:id])
    authorize @offer

    prepare_gmaps_variable @offer
    @contact = Contact.new url: request.url, reporting: true
    respond_with @offer
  end

  private

  ### INDEX ###

  # general variable assignments: search for results, get categories, etc.
  def assign_search_result_instance_variables
    @personal_offers = @search_cache.personal_hits
    @remote_offers = @search_cache.remote_hits
    @category_tree = Category.hash_tree
    @facets = @search_cache.facet_counts_for_query
  end

  # Initialize Search Form Object with given params
  def build_search_cache_and_search page
    @search_cache = SearchForm.new params.for(SearchForm).refine
    @search_cache.search page
  end

  # Set geolocation variables for map
  def set_position
    @position = @search_cache.geolocation
    if @search_cache.search_location == I18n.t('conf.current_location')
      # erase cookie so that next time the current location will be used again
      cookies[:last_search_location] = nil
    else
      # set cookie so that next time the same location will be prefilled
      cookies[:last_search_location] = {
        value: @search_cache.location_for_cookie,
        expires: 3.months.from_now
      }
    end
  end

  # Deal with location fallback and no nearby search results
  def test_location_unavailable
    # See if area is covered and if not instantiate an UpdateRequest
    unless @search_cache.nearby?
      @update_request = UpdateRequest.new(
        search_location: @search_cache.search_location
      )
    end

    # Alert user when we used default location because they didn't give one
    if @search_cache.location_fallback
      flash[:alert] = I18n.t('offers.index.location_fallback')
    end
  end

  ### /INDEX ###
end
