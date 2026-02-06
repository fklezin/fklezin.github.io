FROM jekyll/jekyll:latest

# Copy Gemfile and Gemfile.lock
COPY Gemfile* ./

# Install dependencies
RUN bundle install

# Copy the rest of the site
COPY . .

# Expose the port Jekyll runs on
EXPOSE 4000

# Start Jekyll
CMD ["jekyll", "serve", "--force_polling", "-H", "0.0.0.0"]

