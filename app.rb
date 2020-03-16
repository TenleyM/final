# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "geocoder"
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

ski_areas_table = DB.from(:ski_areas)
reviews_table = DB.from(:reviews)
users_table = DB.from(:users)
@gmaps_apikey = "AIzaSyCtovsQvkIUWlNqtYwXY87gEd4ZSmJEhMw"

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

get "/" do
    puts ski_areas_table.all
    @ski_areas = ski_areas_table.all.to_a
    view "mountains"
end

get "/ski_areas/:id" do
    @ski_area = ski_areas_table.where(id: params[:id]).to_a[0]
    @reviews = reviews_table.where(ski_area_id: @ski_area[:id]).to_a
    @review_count = reviews_table.where(ski_area_id: @ski_area[:id]).count
    @average_quality = reviews_table.where(ski_area_id: @ski_area[:id]).avg(:quality_rating)
    @average_variety = reviews_table.where(ski_area_id: @ski_area[:id]).avg(:variety_rating)
    @users_table = users_table
    @location = @ski_area[:zipcode]
    @geocoder_results = Geocoder.search(@location)
    @lat_long = @geocoder_results.first.coordinates
    puts @location
    view "mountain"
end

get "/ski_areas/:id/reviews/new" do
    @ski_area = ski_areas_table.where(id: params[:id]).to_a[0]
    view "new_review"
end

get "/ski_areas/:id/reviews/create" do
    puts params
    @ski_area = ski_areas_table.where(id: params["id"]).to_a[0]
    reviews_table.insert(ski_area_id: params["id"],
                       user_id: session["user_id"],
                       quality_rating: params["quality"],
                       variety_rating: params["variety"],
                       comments: params["comments"],
                       date: params["date"])
    view "create_review"
end

get "/users/new" do
    view "new_user"
end

post "/users/create" do
    puts params
    hashed_password = BCrypt::Password.create(params["password"])
    users_table.insert(name: params["name"], email: params["email"], password: hashed_password)
    view "create_user"
end

get "/logins/new" do
    view "new_login"
end

post "/logins/create" do
    user = users_table.where(email: params["email"]).to_a[0]
    puts BCrypt::Password::new(user[:password])
    if user && BCrypt::Password::new(user[:password]) == params["password"]
        session["user_id"] = user[:id]
        @current_user = user
        view "create_login"
    else
        view "create_login_failed"
    end
end

get "/logout" do
    session["user_id"] = nil
    @current_user = nil
    view "logout"
end
