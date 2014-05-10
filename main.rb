require 'rubygems'
require 'sinatra'
require 'sinatra/contrib/all'
require 'pry'

set :sessions, true

helpers do
  
  def calculate_total(cards)
   arr = cards.map{|e| e[1] }

  total = 0
  arr.each do |value|
    if value == 'A'
      total += 11

    elsif value.to_i == 0
      total += 10
    else
      total += value.to_i
    end
  end
  
  arr.select{|e| e == 'A'}.count.times do
    total -= 10 if total > 21
  end

  total
  end

end

get '/' do
  erb :set_name

end


post '/set_name' do
  session[:player_name] = params[:player_name] 
  redirect '/game'
end

get '/game' do

session[:deck] = []
suits = ['H', 'D', 'S', 'C']
cards = ['2', '3', '4', '5', '6','7', '8', '9', '10', 'J', 'Q', 'K', 'A']
session[:deck] = suits.product(cards)
session[:deck].shuffle!
session[:player_cards] = []
session[:dealer_cards] = []
session[:player_cards] << session[:deck].pop
session[:dealer_cards] << session[:deck].pop
session[:player_cards] << session[:deck].pop
session[:dealer_cards] << session[:deck].pop
erb :game

end

post '/hit' do
   session[:hits] = params[:hit]
   redirect '/hit'
end

post '/stay' do
   session[:stay] = params[:stay]
   redirect '/stay'
end

get '/profile' do
  erb :"/users/profile"
end
