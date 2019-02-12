class TimelinesController < ApplicationController
  before_action :set_timeline, only: [:show, :edit, :update, :destroy]

  # GET /timelines
  def index
  end

  # POST /timelines/paged_index
  def paged_index
    # Timelines for index page are loaded dynamically by jquery datatables javascript which
    # requests the html for only a limited set of rows at a time.
    recordsTotal = @timelines.count
    columns = ['title','description','visibility','updated_at','tags','actions']

    #Filter title
    title_filter = params['search']['value']
    @timelines = @timelines.title_like(title_filter) if title_filter.present?

    # Apply tag filter if requested
    tag_filter = params['columns']['4']['search']['value']
    @timelines = @timelines.with_tag(tag_filter) if tag_filter.present?
    timelinesFilteredTotal = @timelines.count

    sort_column = params['order']['0']['column'].to_i rescue 0
    sort_direction = params['order']['0']['dir'] rescue 'asc'
    session[:timeline_sort] = [sort_column, sort_direction]
    if columns[sort_column] != 'size'
      @timelines = @timelines.order({ columns[sort_column].downcase => sort_direction })
      @timelines = @timelines.offset(params['start']).limit(params['length'])
    else
      # sort by size (item count): decorate list with timelineitem count then sort and undecorate
      decorated = @timelines.collect{|p| [ p.items.size, p ]}
      decorated.sort!
      @timelines = decorated.collect{|p| p[1]}
      @timelines.reverse! if sort_direction=='desc'
      @timelines = @timelines.slice(params['start'].to_i, params['length'].to_i)
    end
    response = {
      "draw": params['draw'],
      "recordsTotal": recordsTotal,
      "recordsFiltered": timelinesFilteredTotal,
      "data": @timelines.collect do |timeline|
        copy_button = view_context.button_tag( type: 'button', data: { timeline: timeline },
          class: 'copy-timeline-button btn btn-default btn-xs') do
          "<i class='fa fa-clone' aria-hidden='true'></i> Copy".html_safe
        end
        edit_button = view_context.link_to(edit_timeline_path(timeline), class: 'btn btn-default btn-xs') do
          "<i class='fa fa-edit' aria-hidden='true'></i> Edit".html_safe
        end
        delete_button = view_context.link_to(timeline_path(timeline), method: :delete, class: 'btn btn-xs btn-danger btn-confirmation', data: {placement: 'bottom'}) do
          "<i class='fa fa-times' aria-hidden='true'></i> Delete".html_safe
        end
        [
          view_context.link_to(timeline.title, timeline_path(timeline), title: timeline.comment),
          timeline.description,
          view_context.human_friendly_visibility(timeline.visibility),
          "<span title='#{timeline.updated_at.utc.iso8601}'>#{view_context.time_ago_in_words(timeline.updated_at)} ago</span>",
          timeline.tags.join(', '),
          "#{copy_button} #{edit_button} #{delete_button}"
        ]
      end
    }
    respond_to do |format|
      format.json do
        render json: response
      end
    end
  end

  # GET /timelines/1
  # GET /timelines/1.json
  def show
  end

  # GET /timelines/new
  def new
    @timeline = Timeline.new
  end

  # GET /timelines/1/edit
  def edit
  end

  # POST /timelines
  # POST /timelines.json
  def create
    @timeline = Timeline.new(timeline_params)

    respond_to do |format|
      if @timeline.save
        format.html { redirect_to @timeline, notice: 'Timeline was successfully created.' }
        format.json { render :show, status: :created, location: @timeline }
      else
        format.html { render :new }
        format.json { render json: @timeline.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /timelines/1
  # PATCH/PUT /timelines/1.json
  def update
    respond_to do |format|
      if @timeline.update(timeline_params)
        format.html { redirect_to @timeline, notice: 'Timeline was successfully updated.' }
        format.json { render :show, status: :ok, location: @timeline }
      else
        format.html { render :edit }
        format.json { render json: @timeline.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /timelines/1
  # DELETE /timelines/1.json
  def destroy
    @timeline.destroy
    respond_to do |format|
      format.html { redirect_to timelines_url, notice: 'Timeline was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_timeline
      @timeline = Timeline.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def timeline_params
      params.require(:timeline).permit(:title, :user_id, :visibility, :description, :access_token, :tags, :source, :manifest)
    end
end
