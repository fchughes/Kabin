# Kabin

Kabin is an AI-powered macOS tool that generates documentation and scripts from screen recordings and user input captures. Say you've got some tedious task that you or someone else needs to perform again in the future, you could write down all the steps to retrace your steps later, you could write a script that performs the task for you, or you could let Kabin watch you as you do the task and kick back as it spits out documentation and scripts.

## User Guide

Select a folder to store your new task and click "Record"; Kabin will record your keyboard and mouse inputs and relevant info from your screen in order to write documentation and scripts. When you're done with your task or need to take a break, click "Stop Recording" -- you can always continue recording to continue the same task. When you're ready, click "Generate" to generate documentation that makes it easy for others to follow your steps along with a script that does the steps automatically.

## How it Works

Kabin records user keyboard and mouse inputs, taking a screenshot, tagged with the time, pressed key, and open application info. When users click "Generate" we parse this information, packaging it up into something an LLM like GPT can digest. The language model spits out the documentation and generates code which is able to reproduce the actions taken by the user.


