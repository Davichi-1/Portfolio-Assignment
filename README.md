# David Chidera Tobias: portfolio

A static portfolio website (HTML, CSS and JavaScript). Nginx serves it inside a Docker container on an AWS EC2 instance. A push to `main` builds and deploys it automatically with GitHub Actions.

## Live details

Fill these in after the first deployment.

- Website: `http://<EC2_PUBLIC_IP>:8080`
- Container name: `portfolio`
- Website port: `8080` on the server, which maps to port `80` inside the container
- CV: `http://<EC2_PUBLIC_IP>:8080/assets/David-Chidera-Tobias-CV.pdf`
- Running release: `http://<EC2_PUBLIC_IP>:8080/version.txt` shows the commit SHA that is live

## Folder structure

```
index.html                  the whole site
assets/                     images, videos and the CV (David-Chidera-Tobias-CV.pdf)
nginx.conf                  Nginx settings, including /healthz and /version.txt
Dockerfile                  builds the Nginx image and stamps it with the commit SHA
.dockerignore               files kept out of the image
.gitignore                  keeps secrets and local files out of Git
scripts/validate.sh         checks the site before every build
.github/workflows/deploy.yml  the CI/CD pipeline
```

## Run it locally

You need Docker.

```bash
bash scripts/validate.sh
docker build --build-arg GIT_SHA=local -t portfolio:local .
docker run -d --name portfolio-local -p 8080:80 portfolio:local
curl -fsS http://localhost:8080/healthz      # prints: ok
curl -fsS http://localhost:8080/version.txt  # prints: local
```

Open http://localhost:8080 in a browser. Stop it with `docker rm -f portfolio-local`.

## How the pipeline works

`.github/workflows/deploy.yml` runs on every push to `main`, and can also be started by hand from the Actions tab.

1. Check out the code.
2. Run `scripts/validate.sh`. It fails if a section, link, file or the CV is missing, if placeholder text is left, if a private detail is on the page, or if a secret is in the files.
3. Build the Docker image, tagged with the commit SHA.
4. Start the image on the runner and test `/healthz`, `/version.txt` and the home page.
5. Connect to EC2 over SSH. The server's host key is checked against a saved value, and host checking is never turned off.
6. Send the image to EC2 and start it as the container `portfolio`, replacing the old one.
7. Check the public website from outside. The job fails unless `/healthz` answers and `/version.txt` matches the commit that was just pushed.

If any step fails, the whole run fails and shows a red cross.

## GitHub secrets

Add these in the repository under Settings, then Secrets and variables, then Actions. Never put their values in code, logs or screenshots.

| Secret | What it holds |
| --- | --- |
| `EC2_HOST` | the EC2 public IP address |
| `EC2_USER` | the SSH user the pipeline logs in as |
| `EC2_SSH_KEY` | the private key made for deployment only |
| `EC2_KNOWN_HOSTS` | the server's public host key line, from `ssh-keyscan` |

## Rollback

Each deployment keeps the previous version. On the EC2 server:

```bash
cd ~/portfolio-deploy
PREV=$(cat previous_sha)
docker rm -f portfolio
docker run -d --name portfolio --restart unless-stopped -p 8080:80 portfolio:$PREV
echo "$PREV" > current_sha
curl -fsS http://localhost:8080/version.txt   # should print the previous SHA
```

To make the rollback permanent, revert the bad commit in Git and push, so the next pipeline run deploys the reverted code.

## Prove that CI/CD works

1. Change one visible sentence in `index.html`.
2. Commit and push to `main`.
3. Open the Actions tab and wait for the run to turn green.
4. Open the website and check that the sentence changed. Nobody restarted anything by hand.
5. Open `/version.txt` and check that it matches the commit SHA of that run.
# Portfolio-Assignment
