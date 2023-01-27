// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

uint256 constant INITIAL_BALANCE = 17500;

uint256 constant INIT_ACCEL_COST = 12;

uint256 constant ACCEL_FLOOR = 15;
uint256 constant SHELL_FLOOR = 200;
uint256 constant SUPER_SHELL_FLOOR = 300;
uint256 constant SHIELD_FLOOR = 400;
uint256 constant BANANA_FLOOR = 200;

enum Strat {
    LAG, // stick to 3rd place, but close enough to 2nd car
    HODL, // hold your spot
    BLITZKRIEG // all out war
}

struct TurnState {
    bool leading;
    uint256 speed;
    uint256 initialBalance;
    uint256 balance;
    uint256 y;
    uint256 pctLeft;
    uint256 remainingTurns;
    uint256 targetSpend;
}
