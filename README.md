# furaffinity

A gem to interface with FurAffinity, along with a neat little CLI.

## Installation

```sh
gem install furaffinity
```

## Usage

CLI usage is as follows:

```sh
# replace "cookie-a" and "cookie-b" with the values of the respective cookies
# use firefox's web inspector for that, the "Storage" tab displays it nicely
fa auth cookie-a cookie-b

# retrieve your notification counters as JSON
fa notifications
# {
#   "submissions": 30944,
#   "watches": 317,
#   "comments": 278,
#   "favourites": 1018,
#   "journals": 1642,
#   "trouble_tickets": 9
# }

# upload a new submission
fa upload my_image.png --title "test post please ignore" --description "This is an image as you can see" --rating general --scrap

# interactively update a submission, this needs your preferred editor in ENV
export EDITOR=vi
fa edit 54328944
```

There is also a way to upload submissions in bulk: `fa queue`

```sh
# set your preferred editor in ENV
export EDITOR=vi

# initialise queue directory
fa queue init my_queue
cd my_queue

# copy files to upload into the queue directory
cp ~/Pictures/pic*.png .

# add files, an editor will open up for each file to fill in the details
fa queue add pic1.png
fa queue add pic2.png pic3.png

# see the status of the queue
fa queue status

# use your preferred editor to change the submission information afterwards
vi pic2.png.info.yml

# open up an editor to rearrange the queue order
fa queue reorder

# upload the entire queue
fa queue upload

# once everything's uploaded you can remove the already uploaded pics
fa queue clean
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nilsding/furaffinity. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/nilsding/furaffinity/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [AGPLv3 License](https://opensource.org/license/agpl-v3/).

## Code of Conduct

Everyone interacting in the Furaffinity project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/nilsding/furaffinity/blob/main/CODE_OF_CONDUCT.md).
