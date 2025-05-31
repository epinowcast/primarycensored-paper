# PR Plan: Human review of data ingestion and function reorganization

## Idea dump to refactor

The first step is to view the  issue and understand the problem.
Then we need to update this plan to cover in detail all the steps we need to take to fix the issue.
As we fix them we need to refer back to the plan.
Then review the targets.Rmd where we ill need to make changes and the main.qmd
The gold standard analysis plan is in paper/main.qmd.
I an worried that we only have expontialtitled growth rate simulated data but in the paper we say: Primary events were assumed to follow a uniform distribution within their censoring windows.

i.e the growht rate is 0. I think I like the idea of doing both i.e one with growth rate 0 and one with growth rate 2. where the former is equiv to the uniform distribution we say we dido

We will need to update the paper to be clear there are now 18 datasets and update the targets.Rmd to reflect this change.

## Current Status

We are going to make a PR for the above issue.

## Implementation Plan

## Testing Strategy

After each task:
1. Run `task render` to update _targets.R from _targets.Rmd
2. Run `task run` to test the pipeline
3. If errors occur, use `targets::tar_make(target_name)` to debug specific targets
4. Commit changes after each successful task completion

## Key Principles
- All changes must be made in _targets.Rmd, not in the generated files
- Use primarycensored package functions where possible
- Maintain compatibility with existing structure
- Test incrementally - one task at a time
- Document changes clearly in code comments
