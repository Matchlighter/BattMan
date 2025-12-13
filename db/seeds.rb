# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

def tag_type(type, **options)
  TagType.find_or_create_by(id: type) do |tt|
    tt.assign_attributes(options)
  end
end

tag_type "template", typing: :boolean, inheritable: false
tag_type "builtin", typing: :boolean, inheritable: false
tag_type "can-belong-to", typing: "string[]"
tag_type "belongs-to", typing: :reference, inheritable: false

def define_template(type, *tags)
  tags << "template"
  tags << "builtin"

  computed_tags = {}
  computed_tags[type] = {}
  tags.each do |t|
    if t.is_a?(Hash)
      computed_tags.merge!(t)
    else
      computed_tags[t] = true
    end
  end

  Thing.find_by(id: type) || Thing.create!(
    id: type,
    own_tags: computed_tags,
  )
end

define_template("Location",
  "can-belong-to" => ["Location"],
)

define_template("Item",
  "can-belong-to" => ["Location"],
  "maintenance-schedule" => {},
)

# Define a "Class" of Item that you may have multiple instances/copies of
#   eg You might have 3 of the same model of TV.
#     Each was bought on a different date, has a different S/N, etc.
#     But they all have the same manual, warranty terms, etc.
define_template("Product",
  "product",
)

define_template("Appliance",
  "warranty" => {},
  "manual" => {},
  "implements" => ["Item"]
)

define_template("Device",
  "implements" => ["Item"],
  "uses-batteries" => true,
)

define_template("Battery",
  "implements" => ["Item"],
  "can-belong-to" => ["uses-batteries"],
  "last-charged" => {}
)

Thing.roots.each(&:refresh_tag_cache!)
