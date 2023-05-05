import json
import sys

# Open the input file specified as a command-line argument
with open(sys.argv[1]) as f:
    data = json.load(f)

# Extract the relevant data from the JSON
discussions = data['data']['repository']['discussions']['nodes']
basename = sys.argv[1].split('.')[0]

# Generate the markdown
markdown = ''
for discussion in discussions:
    markdown += f'# {basename}_{discussion["number"]}\n'
    markdown += f'###### Created: {discussion["createdAt"]}\n'
    markdown += f'#### {discussion["author"]["login"]}\n'
    markdown += f'## {discussion["title"]}\n'
    markdown += f'{discussion["body"]}\n'

    for comment in discussion['comments']['nodes']:
        markdown += f'---\n'
        markdown += f'#### {comment["author"]["login"]}\n'
        markdown += f'{comment["body"]}\n'

# Print the markdown to the console
print(markdown)
