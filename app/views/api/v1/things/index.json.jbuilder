json.partial! 'miscellany/slice', slice: @sliced_data do |thing|
  json.partial! 'thing', thing: thing
end
