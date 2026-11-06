# Spec: Make "Join Event Board" the main entry point (live turns on automatically)

Being live is required for event boards, but users shouldn't have to think
about "going live." Joining an event board starts live automatically.

## Status
- [x] #1 Event code on round setup (auto-starts live + links event)
- [ ] #2 Deep link to join an event
- [x] #3 Mid-round "Join Event" action
- [x] #4 Live status pill in header
- [x] #5 Replace showGoLiveCreatedAlert with a toast
- [ ] #6 Make leave vs. stop behavior clear
- [ ] #7 Clean up the action sheet
- [x] #8 Remove dead showLiveCodePrompt code

## #2 Deep link
- Add wolfmore://event?code=XXXX, following the existing wolfmore://watch?code= handling.
- If a round is in progress: join that event (start live if needed).
- If no round is in progress: save the code and pre-fill the Event code field on round setup.

## #3 Mid-round "Join Event"
- Replace the current two-field Go Live dialog (group name + event code) with a
  single-field "Enter event code" prompt.
- Submitting it starts live (if not already live) and links the event (liveLinkedEventCode).
  Fill in the group name automatically. Don't ask for it.
- Keep a separate, secondary "Go Live (spectators only)" option with no event code.

## #6 Leave vs. stop
- "Leave Event Board" keeps the live session running.
- "Stop Live" while on a board: show a confirmation first:
  "This will also remove your group from event board XXXX."

## #7 Clean up the action sheet
- Move "Start an Event Board…" out of the player's live sheet and into a
  home/menu or organizer area.
- The remaining sheet buttons are Share Code, Copy Code, Join/Leave Event Board, and Stop Live.
