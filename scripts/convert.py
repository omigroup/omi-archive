import argparse
import json

def parse_json(json_file, num_discussions, fields, show_comments):
    with open(json_file, 'r') as f:
        data = json.load(f)

    discussions = data['data']['repository']['discussions']['nodes']

    for discussion in discussions[:num_discussions]:
        for field in fields:
            if field in discussion:
                print(f"{field}: {discussion[field]}")
            elif field in discussion['category']:
                print(f"{field}: {discussion['category'][field]}")
            elif field == 'author.login':
                print(f"{field}: {discussion['author']['login']}")

        if show_comments:
            print("Comments:")
            for comment in discussion['comments']['nodes']:
                print(f"{comment['author']['login']}: {comment['body']}")

        print("\n")


def main():
    parser = argparse.ArgumentParser(description="Parse JSON data from GraphQL query.")
    parser.add_argument("json_file", type=str, help="Path to JSON file.")
    parser.add_argument("--num_discussions", type=int, default=1, help="Number of discussions to display.")
    parser.add_argument("--fields", type=str, nargs='+', default=['title', 'author.login'], help="Fields to include in the output.")
    parser.add_argument("--show_comments", action='store_true', help="Include comments in the output.")

    args = parser.parse_args()
    parse_json(args.json_file, args.num_discussions, args.fields, args.show_comments)

if __name__ == "__main__":
    main()
