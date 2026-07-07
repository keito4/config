/* global Application */

const BTT = Application('/Applications/BetterTouchTool.app');

const aerospace = '/opt/homebrew/bin/aerospace';

const shellTriggers = [
  {
    uuid: 'CODEX-BTT-AEROSPACE-WORKSPACE-NEXT',
    type: 100,
    description: '3 Finger Swipe Left',
    name: 'AeroSpace workspace next',
    command: `${aerospace} workspace --wrap-around next`,
    order: 10,
  },
  {
    uuid: 'CODEX-BTT-AEROSPACE-WORKSPACE-PREV',
    type: 101,
    description: '3 Finger Swipe Right',
    name: 'AeroSpace workspace previous',
    command: `${aerospace} workspace --wrap-around prev`,
    order: 20,
  },
  {
    uuid: 'CODEX-BTT-AEROSPACE-WORKSPACE-BACK',
    type: 104,
    description: '3 Finger Tap',
    name: 'AeroSpace workspace back and forth',
    command: `${aerospace} workspace-back-and-forth`,
    order: 30,
  },
  {
    uuid: 'CODEX-BTT-AEROSPACE-FOCUS-LEFT',
    type: 105,
    description: '4 Finger Swipe Left',
    name: 'AeroSpace focus left',
    command: `${aerospace} focus left`,
    order: 40,
  },
  {
    uuid: 'CODEX-BTT-AEROSPACE-FOCUS-RIGHT',
    type: 106,
    description: '4 Finger Swipe Right',
    name: 'AeroSpace focus right',
    command: `${aerospace} focus right`,
    order: 50,
  },
  {
    uuid: 'CODEX-BTT-AEROSPACE-FOCUS-DOWN',
    type: 107,
    description: '4 Finger Swipe Down',
    name: 'AeroSpace focus down',
    command: `${aerospace} focus down`,
    order: 60,
  },
  {
    uuid: 'CODEX-BTT-AEROSPACE-FOCUS-UP',
    type: 108,
    description: '4 Finger Swipe Up',
    name: 'AeroSpace focus up',
    command: `${aerospace} focus up`,
    order: 70,
  },
  {
    uuid: 'CODEX-BTT-RAYCAST',
    type: 110,
    description: '4 Finger Tap',
    name: 'Open Raycast',
    command: '/usr/bin/open -a Raycast',
    order: 80,
  },
];

const directTriggers = [
  {
    BTTUUID: 'CODEX-BTT-CMD-W',
    BTTTriggerType: 103,
    BTTTriggerTypeDescription: '3 Finger Swipe Down',
    BTTTriggerClass: 'BTTTriggerTypeTouchpadAll',
    BTTPredefinedActionType: 264,
    BTTPredefinedActionName: 'Send Keyboard Shortcut',
    BTTShortcutToSend: '55,13',
    BTTEnabled: 1,
    BTTEnabled2: 1,
    BTTOrder: 25,
  },
  {
    BTTUUID: 'CODEX-BTT-MIDDLE-CLICK',
    BTTTriggerType: 112,
    BTTTriggerTypeDescription: '3 Finger Click',
    BTTTriggerClass: 'BTTTriggerTypeTouchpadAll',
    BTTPredefinedActionType: 1,
    BTTPredefinedActionName: 'Middle Click',
    BTTEnabled: 1,
    BTTEnabled2: 1,
    BTTOrder: 90,
  },
];

const triggers = [
  ...shellTriggers.map((trigger) => ({
    BTTUUID: trigger.uuid,
    BTTTriggerType: trigger.type,
    BTTTriggerTypeDescription: trigger.description,
    BTTTriggerClass: 'BTTTriggerTypeTouchpadAll',
    BTTPredefinedActionType: 137,
    BTTPredefinedActionName: trigger.name,
    BTTTerminalCommand: trigger.command,
    BTTEnabled: 1,
    BTTEnabled2: 1,
    BTTOrder: trigger.order,
  })),
  ...directTriggers,
];

const existing = JSON.parse(BTT.get_triggers());
const existingUuids = new Set(existing.map((trigger) => trigger.BTTUUID));

let addedTriggers = 0;
for (const trigger of triggers) {
  if (existingUuids.has(trigger.BTTUUID)) {
    continue;
  }

  BTT.add_new_trigger(JSON.stringify(trigger));
  existingUuids.add(trigger.BTTUUID);
  addedTriggers += 1;
}

JSON.stringify({
  preservedExistingTriggers: existing.length,
  addedTriggers,
  managedTriggers: triggers.length,
});
