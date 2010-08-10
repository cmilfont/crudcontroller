module CrudController

  def self.included( base )
    base.extend( CrudController::ClassMethods )
  end

  module ClassMethods

    def generate_for(model)
      model = model.to_s
      klass_name = model.camelize
      plural  = model.pluralize

      class_eval %Q!

        before_filter :load_page, :load_conditions, :only => :index
        before_filter :load_#{model}, :only => [ :edit, :new, :create, :update, :destroy ]

        def index
          load_records
          respond_to do |format|
            format.html
            format.json { render :json => { :results => @#{plural},
                                            :total => @#{plural}.total_entries
                                           }.to_json( to_json_options )
                        }
          end
        end

        def show
          @#{model} = #{klass_name}.find(params[:id])
        end

        def edit
          on_edit( @#{model} )
          render :edit
        end

        alias :new :edit

        def create
          create_or_update
        end

        def update
          create_or_update
        end

        def destroy
          @#{model}.destroy
          respond_to do |format|
            format.json  { render :json => {
                                             :success => 'true'
                                           }
                         }
          end
        end

        protected

        def load_records
          @#{plural} = paginate( #{klass_name}, (paginate_options.merge({:conditions => @conditions})) )
        end

        def paginate_options
          {}
        end

        def to_json_options
          {}
        end

        def on_edit(record)
        end

        def on_create_or_update(record)
        end

        def load_#{model}
          @#{model} = params[:id].blank? ? #{klass_name}.new : #{klass_name}.find(params[:id])
        end

        def paginate( #{model}, options = {} )
          #{model}.paginate( { :page => @page, :per_page => @per_page }.merge(options) )
        end

        def load_page
          @page = params[:page] || '1'
          @per_page = (params[:limit] || '100').to_i
          true
        end

        def create_or_update
          on_create_or_update( @#{model} )
          status = @#{model}.new_record? ? :created : :ok
          if @#{model}.update_attributes(params[:#{model}])
            respond_to do |format|
              format.html { redirect_to(@#{model}) }
              format.json  { render :json => {
                                               :success => 'true',
                                               :id => @#{model}.id,
                                               :record => @#{model}
                                             },
                                    :status => status,
                                    :location => @#{model}
                            }
            end
          else
            respond_to do |format|
              @errors = { :attributes => {}, :base => @#{model}.errors.on_base}

              @#{model}.errors.each do |attr, msg|
                @errors[:attributes]["#{model}_\#{attr}"]    ||= []
                @errors[:attributes]["#{model}_\#{attr}_id"] ||= []
                @errors[:attributes]["#{model}_\#{attr}"]    << msg
                @errors[:attributes]["#{model}_\#{attr}_id"] << msg
              end

              format.html { render :action => "new" }
              format.json  { render :json => { :success => 'false',
                                               :errors => @errors
                                             },
                                    :status => :unprocessable_entity,
                                    :location => @#{model}
                           }
            end
          end
        end

        def load_conditions
          fieldsForSearch = eval(params[:fields]) if params[:fields]


          query = params[:query] if params[:query]

          aditional_filter = params[:aditionalFilter] ? params[:aditionalFilter] : ''

          if (query == "")
            query = false
          end

          conditions_array = []

          if (fieldsForSearch && query)
            fieldsForSearch.each do |field|
              if (#{klass_name}.columns_hash[field].type == :string)
                conditions_array << \"UPPER(\#{field}) LIKE UPPER('%\#{query}%'\)"
              else
                if (query.to_i \!= 0)
                  conditions_array << \"\#{field} = \#{query}\"
                end
              end
            end
          end

          conditions_array << \"\#{aditional_filter}\" unless aditional_filter.blank?

          @conditions = conditions_array.join(' OR ')
        end

      !

    end

  end

end

