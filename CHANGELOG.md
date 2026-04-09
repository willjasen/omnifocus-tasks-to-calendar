# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2026-04-09]

### Added

- option to log runtime performance to CSV

### Changed

- the script now specifies a minimum config version
- config examples for each version are located under the `examples` directory
- allow for daysAhead and daysBack to be specified per config index

## [2026-03-25]

### Added

- Smart sync: match events by task ID

### Changed

- Move script data into a JSON file

### Fixed

- Fix Calendar error on some macOS systems

## [2026-01-26]

### Added

- Support "planned date" attribute
- Exclude dropped tasks from sync

## [2025-05-30]

### Added

- Minimize Calendar app when script runs
- Added command-line usage comments

## [2025-02-20]

### Changed

- Single processing-tasks handler

## [2024-08-19]

### Added

- Calendar alert aligns with task's due date

### Changed

- Shared tags no longer need to be primary tag
- Refactored script to use handlers

## [Initial] - [willjasen](https://willjasen.com)

### Added

- Copy task notes into calendar event notes

### Changed

- Only add events from today forward (decreases runtime)

### Fixed

- Fixed task_start_date calculation to use task_end_date

## [Original] - [Rosemary Orchard](https://rosemaryorchard.com/)

### Added

- Modified from a script by unlocked2412
- Default to 30 min if no estimated time is set
