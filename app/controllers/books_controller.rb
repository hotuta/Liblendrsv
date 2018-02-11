class BooksController < ApplicationController
  def index
    @books = TokaiLend.all
    render body: TokaiLend.icalendar(@books)
  end
end
