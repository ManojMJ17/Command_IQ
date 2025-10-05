# #!/usr/bin/env python
# import sys
# from cli.predict import CommandPredictor


# def main():
#     if len(sys.argv) < 2:
#         print("\nUsage: ciq \"your query\"")
#         return

#     query = " ".join(sys.argv[1:])
#     predictor = CommandPredictor()
#     predicted_command = predictor.predict(query)

#     if not predicted_command.strip():
#         print("Model could not generate a command for your query.")
#         return

#     print(f"\nPredicted Command: {predicted_command}\n")
    
#     predictor.run_command(predicted_command) 

# if __name__ == "__main__":
#     main()



# cli/main.py
import click
from cli.predict import CommandPredictor

@click.command()
@click.argument("query", required=False)
@click.option('--help', is_flag=True, help="Show this message and exit")
def main(query, help):
    if help:
        click.echo("\nCIQ - Offline NL-to-Linux Command Translator.\n")
        click.echo("Usage:")
        click.echo("  ciq \"your natural language query\"")
        click.echo("  ciq --help\n")
        return

    if query is None:
        click.echo("Error: Missing query. Use --help for usage.")
        return

    predictor = CommandPredictor()

    # ---- HYBRID PIPELINE ----
    faiss_cmds = predictor.faiss_search(query)
    faiss_cmd = faiss_cmds[0] if faiss_cmds else ""
    t5_cmd = predictor.t5_predict(query)
    final_cmd = predictor.predict(query)

    click.echo("\n=====================================")
    click.echo(f"Query         : {query}")
    click.echo(f"FAISS Suggest : {faiss_cmd}")
    click.echo(f"T5 Suggest    : {t5_cmd}")
    click.echo(f"Final Suggest : {final_cmd}")
    click.echo("=====================================")

    choice = input("\nRun this command? [y/n]: ").strip().lower()
    if choice == "y":
        predictor.run_command(final_cmd)
    else:
        click.echo("Cancelled.")

if __name__ == "__main__":
    main()
