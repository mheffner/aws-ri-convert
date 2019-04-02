# Aws::Ri::Convert

This tool helps manage AWS EC2 Convertible Reserved Instances in order
to maximize the utilization of your already purchased cloud spend. It
will automatically adjust convertible RIs to cover the current
usage. It has been used to maintain RI utilization rates of 95%+ while
allowing maximum flexibility for the organization to choose the right
instance class/type for the job without lengthy
planning/pre-approvals. It was originally inspired by [some
work](https://engineering.quora.com/Automated-Infrastructure-Cost-Optimization-at-Scale-with-AWS-EC2-Reserved-Instances)
by the Quora team.

## WARNING

**READ THIS FIRST:**

This tool can and will modify your reserved instances based on
utilization and coverage reports. If not operated correctly or run
under the strict requirements below your RIs may not align with usage
and hence generate higher on-demand instance charges. The script will
also generate charges when it must modify an RI to adjust to current
usage. The charges are designed to be minor and the tool should prompt
before generating any purchase. You should be familiar with AWS
CostExplorer and the EC2 RI console to verify expected results.

This tool has been run on a limited number of account scenarios, so
YMMV. All feedback is welcome.

**No warranty included.**

## Operating requirements

This tool was built to optimize for particular models of EC2 RI
purchasing and EC2 usage. While it can and should be expanded to more
scenarios, you should know that it works best under the following
guidelines at the moment. Obviously, I'm open to accept PRs that
expand the scenarios this tool can optimize for.

Unfortunately, it is not always possible to detect a
miss-configuration so you should ensure you meet these requirements so
that outcomes are expected.

### Single AWS account with RIs/Cost Data

This tool operates within a single account by modifying RIs to
maximize their coverage of on-demand/running instances. This means you
either need 1) a single AWS account, or 2) single payer root account
with access to all RIs and full Cost Explorer data. RIs are shared
across linked accounts at the end of the month, but CostExplorer will
not show correct utilization from a single account. If you have a
single payer root account over multiple linked accounts, the EC2 RIs
should exist in that root account -- ask an account manager to move
them if not.

### Three-year, convertible RIs

This tool maximizes the utilization of already purchased RIs by
matching them to current instance usage. The 3-year RIs are the most
cost effective purchasing option if you have the ability to cover
purchasing 3-years out and your workload is at all dynamic.

*TODO: explain why this is most cost effective model*

### Region scoped RIs

With advent of [Capacity
Reservations](https://aws.amazon.com/about-aws/whats-new/2018/10/Amazon-EC2-now-offers-On-Demand-Capacity-Reservations/)
there is little reason to purchase anything other then Region Scoped
RIs. Region scoped RIs mean that regardless of where the capacity
runs, as long as it is running in the same region it'll be covered by
the matching instance class RI. If you must ensure capacity in
particular AZs, you should manage that with Capacity Reservations
separately.

This good news is that you can modify capacity reservations to region
scope reservations at no charge. This tool has an option to automate
this conversion for all your RIs (see below).

### Linux, VPC, Misc

This tool only operates on Linux RIs. Windows and other license-based
RIs have different cost dynamics, so this tool is not currently
designed for them. Similarly, this is optimized for VPC RIs, though it
likely wouldn't be too difficult to adjust for Classic ones.

## Installation

Checkout the repo and run bundle install:

```
$ bundle install
```

## Running

For all commands you must have the following environment variables set
to the IAM user that has permission to the EC2, CostExplorer and
Pricing APIs. (TODO: explicitly list the required perms)

* `AWS_ACCESS_KEY`: key
* `AWS_SECRET_ACCESS_KEY`: secret key
* `AMAZON_AWS_ID`: numerical account ID

### Converting AZ RIs to Region Scoped

Convert all RIs to region scoped:

```
$ bundle exec ./bin/aws-ri-convert --ri-make-regional --ri-region <us-east-1, us-west-2, ...>
```

### Join all RIs into minimal RI list

Combine all RIs into single instance RIs, using the base size (nano or
large) as the unit. RIs with different end dates *will not* be
combined as that can adjust their coverage. This can reduce sprawl of
RIs after multiple conversions or due to separate purchasing.

```
$ bundle exec ./bin/aws-ri-convert --ri-join --ri-region <us-east-1, us-west-2, ...>
```

### Convert RIs to match usage

**Before running:** make sure to remove any files under `checkpoints/`
  if you haven't run this in several days. These files allow you to
  restore a previous run, but can become stale. (TODO: timestamp
  checkpoints and reject them after a duration)

This is the main operating command that will convert any unused RI
hours to cover current usage. It is an interactive process that walks
through several stages and will prompt for confirmation to make any
change that requires making a purchase, notably modifying an
RI. Unfortunately, due to very long API update times, a single
operation can take tens of minutes to complete. The program will
prompt a status update as it waits, but be prepared for a single run
to take up to an hour.

This tool leverages data from the CostExplorer (CE) API to find unused
RIs and on-demand capacity. The CostExplorer API can take several days
to become accurate after any change, so you should only run this
command at least a week after any change to RIs (including the ones
this tool can make). Similarly, it can take several days for the
changes to be visible in the CostExplorer console. This tool is built
around the model that running it once every 2-4 weeks is sufficient to
adjust to usage changes in an account while maintain 95%+ utilization.

```
$ bundle exec ./bin/aws-ri-convert --ri-conversion --ri-region $REGION
```

Set `$REGION` to the particular region you want to operate on, for
example `us-east-1`, `us-west-2`, etc.

This will follow the basic steps:

1. Run a CE utilization report to find unused RIs
1. Run a CE coverage report to find on-demand capacity
1. Split out the unused RI capacity
1. Convert all unused RI capacity to the exchange type (t2.nano) ($$)
1. Convert the exchange type instance to the on-demand capacity,
starting with the highest value exchange ($$)

This script will take checkpoints along the way and dump several YAML
files in the `checkpoints/` directory. These checkpoints allow the
program to be restarted at certain phases, which is important since it
is updating RI information and they may no longer match what
CostExplorer reports.

Only one exchange to match on-demand capacity is performed in each run
of the script. At the end of a run it will print out the exchange
report, showing remaining on-demand capacity. If there are instances
with ECD usage > zero, simply re-run the same script and it will
pickup the next change from the checkpoint files.

When you've covered all instances or you are out of RI capacity (time
to make more RI purchases?) then remove files under the `checkpoints/`
directory.

Changes will take several days to appear in CostExplorer so be
patient. Make sure you look at the RI Utilization and Coverage reports
using the new [normalized
units](https://aws.amazon.com/about-aws/whats-new/2019/02/normalized-units-information-for-amazon-ec2-reservations-in-aws-cost-explorer/)
mode. Comparing RI usage by hours
is useless because 100 hours of a t2.nano is not the same as 100 hours
of an i3.8xlarge.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mheffner/aws-ri-convert.

## References

* [Cost Optimization at Scale -
  Quora](https://engineering.quora.com/Automated-Infrastructure-Cost-Optimization-at-Scale-with-AWS-EC2-Reserved-Instances)
* [On-Demand Capacity Reservations -
  AWS](https://aws.amazon.com/about-aws/whats-new/2018/10/Amazon-EC2-now-offers-On-Demand-Capacity-Reservations/)
* [CostExplorer Normalized Units -
  AWS](https://aws.amazon.com/about-aws/whats-new/2019/02/normalized-units-information-for-amazon-ec2-reservations-in-aws-cost-explorer/)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
