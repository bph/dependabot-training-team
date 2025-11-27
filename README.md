# Script to add set up Dependabot for

Following the Training team's Handbook page [Setting Up Dependabot for WP Training Team repositories](https://make.wordpress.org/training/handbook/training-team-how-to-guides/setting-up-dependabot-for-wp-training-team-repositories/)

Note: it only handles composer.json or package.json in repos root directory. 

How to use it? 
Download it to your computer
Before you use it fork the particular repo to your local directory. 

## Prompts for:
- repo directory
- GitHub username
- project type (Composer, npm, or both)
## Creates:
- a new branch in the repo directory 
- .github/dependabot.yml (3 variants: Composer, npm, or both)
- .github/workflows/dependabot-auto-approve.yml
- .github/workflows/dependabot-auto-merge.yml
