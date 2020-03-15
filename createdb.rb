# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :ski_areas do
  primary_key :id
  String :ski_area_name
  String :location
  String :latitude
  String :longitude
end

DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password 
end

DB.create_table! :reviews do
  primary_key :id
  foreign_key :ski_area_id
  foreign_key :user_id
  Fixnum :quality_rating
  Fixnum :variety_rating
  String :comments, text: true
  String :date
end

# Insert initial (seed) data
ski_areas_table = DB.from(:ski_areas)

ski_areas_table.insert(ski_area_name: "Mount Bachelor", 
                    location: "Bend, Oregon",
                    latitude: "43.9791812",
                    longitude: "-121.6973873",)

ski_areas_table.insert(ski_area_name: "Stowe Mountain Resort", 
                    location: "Stowe, Vermont",
                    latitude: "44.5302928",
                    longitude: "-72.783631",)

ski_areas_table.insert(ski_area_name: "Lake Louise Ski Resort", 
                    location: "Lake Louise, Alberta, Canada",
                    latitude: "51.4419239",
                    longitude: "-116.1643657",)

