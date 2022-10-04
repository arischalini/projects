# -*- coding: utf-8 -*-
"""
Created on Tue Oct 26 15:00:15 2021

@author: mrcha
"""

import time

import random

import math

import os

class Map_object:
    """These are map objects that will be placed in dictionary that belongs to the map class."""

    def __init__(self,type="avatar"):
        self.type = type

    def __repr__(self):
        if self.type == "avatar":
            return "😊"
        elif self.type == "target":
            return "🎯"
        elif self.type == "dog":
            return "🐶"
        elif self.type == "poop":
            return "💩"
        elif self.type == "win":
            return "✨"
        elif self.type == "wrong":
            return "🤔"
        elif self.type == "lose":
            return "😭"

class Map:
    """Contains the board size and rememberes where the Map_objects are located
    on the coordinate plane."""

    def __init__(self,size=5):
        self.size = size
        self.plane_dict = dict()
        self.plane_list = list()
        #Create dictionary of all locations on this coordinate plane.
        for column in reversed(range(-self.size,self.size+1)):
            for row in range(-size,size+1):
                self.plane_dict[(row,column)]=None
        #Create a list of all coordinate positions.
        for column in reversed(range(-self.size,self.size+1)):
            row_list = [(row,column) for row in range(-self.size,self.size+1)]
            self.plane_list.append(row_list)

    def clear_map(self):
        for key in self.plane_dict:
            self.plane_dict[key]=None

    def __repr__(self):
        all_strings = []
        for row in self.plane_list:
            row_string = ""
            for tup in row:

                if self.plane_dict[tup] is not None:
                    row_string += "   " + str(self.plane_dict[tup]) + "   "
                elif tup[0] == 0 or tup[1] == 0:
                    row_string += "   ⬜   "
                else:
                    row_string += "   ⚪   "
            all_strings.append(row_string)

        plane_string = "\033[2;31;40m"+ ( "\n" + (" "*len(all_strings[0]) + " "*(self.size*2+7) + "\n")*3).join(all_strings)

        return plane_string

class Game_data():
     """This class creates and holds all information necessary for the current level."""

     def __init__(self,current_data=None):
         self.current_data = current_data

     def data_generator(self,difficulty):

         object_x = random.randint(-5,5)
         object_y = random.randint(-5,5)
         task_object_location = (object_x,object_y)

         if difficulty == 1:
             task = "How do you get to (" + str(object_x) + "," + str(object_y) + ")?"
             avatar_location = (0,0)
             if object_x > 0:
                x_answer = "d"*object_x
             else:
                x_answer = "a"*abs(object_x)
             if object_y > 0:
                y_answer = "w"*object_y
             else:
                y_answer = "s"*abs(object_y)
             task_answer = x_answer + y_answer

         elif difficulty == 2:
             task = "Go get your dog! \n What change in x and change in y do you need?"
             avatar_x = random.randint(-5,5)
             avatar_y = random.randint(-5,5)
             while avatar_x == object_x and avatar_y == object_y:
                 avatar_x = random.randint(-5,5)
                 avatar_y = random.randint(-5,5)
             avatar_location = (avatar_x,avatar_y)
             if (object_x-avatar_x) > 0:
                 stringx = str(object_x-avatar_x)
             elif (object_x-avatar_x) == 0:
                 stringx = "0"
             else:
                 stringx = str(object_x-avatar_x)
             if (object_y-avatar_y) > 0:
                 stringy = str(object_y-avatar_y)
             elif (object_y-avatar_y) == 0:
                 stringy = "0"
             else:
                 stringy = str(object_y-avatar_y)
             task_answer = "<" + stringx + "," + stringy + ">"

         elif difficulty == 3:
             task = "How far is the poop? \n Round your answer and include one digit past the decimal point."
             avatar_x = random.randint(-5,5)
             avatar_y = random.randint(-5,5)
             while avatar_x == object_x and avatar_y == object_y:
                 avatar_x = random.randint(-5,5)
                 avatar_y = random.randint(-5,5)
             avatar_location = (avatar_x,avatar_y)
             task_answer = round(math.sqrt((object_x-avatar_x)**2 + (object_y-avatar_y)**2),1)

         self.current_data = [difficulty,avatar_location,task_object_location,task,task_answer]

class User_interface:
    """This class consists of all user-facing dialog and the user's input strings."""

    def __init__(self,difficulty = None,speed = None,last_input = "",score=0,is_correct=None, on_time=None):
        self.last_input = last_input
        self.difficulty = difficulty
        self.speed = speed
        self.score = score
        self.on_time = on_time
        self.is_correct = is_correct

    def start_menu(self):
        print("Welcome to the Coordinate Plane Learning Activity!")
        print("""
              Choose your difficulty: [1] Easy [2] Medium [3] Hard.

              [1] Use the arrow keys to show how you'd get to the target.
              [2] Use change in x and change in y to show how you'd get to your dog.
              [3] Figure out your distance from the poop using the pythagorean theorem.

              Choose your speed: [1] Slow [2] Medium [3] Fast

              [1] You must input your answer in 18 seconds for it to be valid.
              [2] You must input your answer in 12 seconds for it to be valid.
              [3] You must input your answer in 6 seconds for it to be valid.
              """)

        while self.difficulty not in [1,2,3] and self.speed not in [1,2,3]:
            print("Please enter a valid difficulty and speed")
            self.difficulty = int(input("Enter your difficulty: "))
            self.speed = int(input("Enter your speed: "))

    def timed_input(self):

        if self.difficulty == 1:
            print("""
                  Please type...

                  an "a" for each step to the left...
                  a "d" for each step to the right...
                  an "s" for each step down...
                  a "w" for each step up...

                  Example => "aawww" means two units left and three units up.

                  Make sure your string has no spaces and then hit enter.
                  """)
        elif self.difficulty == 2:
            print("""
                  Please type your answer in the format...

                  <a,b> Where a is the change in x and b is the change in y.

                  Example => "<4,-5>" means four units right and five units down.

                  Make sure your string has no spaces and then hit enter.
                  """)
        elif self.difficulty == 3:
            print("""
                  Please enter your answer as a number rounded to the nearest tenth.

                  If your answer is an integer, please include the zero.

                  Examples of acceptable inputs => "3.2" or "4.0"

                  Make sure not to include any spaces and then hit enter.
                  """)

        if self.speed == 1:
            time_allowed = 18
        elif self.speed == 2:
            time_allowed = 12
        elif self.speed == 3:
            time_allowed = 6

        start = int(time.time())
        self.last_input = input("Type your answer with no quotations here: ")
        finish = int(time.time())

        if finish - start <= time_allowed:
            self.on_time = True
        else:
            self.on_time = False

    def feedback_message(self):
        print("Your answer was: " + self.last_input)
        if self.on_time == True:
            print("You responded on time. Your answer will count.")
        elif self.on_time == False:
            print("You responded too late. Your answer will not count.")

    def get_answer_coord(self):
        if self.difficulty == 1:
            x=0
            y=0
            for direction in self.last_input:
                if direction == "a":
                    x-=1
                elif direction == "d":
                    x+=1
                elif direction == "s":
                    y-=1
                elif direction == "w":
                    y+=1
            return (x,y)
        elif self.difficulty == 2:
            insides = self.last_input[1:-1]
            comma_index = insides.index(",")
            x = str(insides[:comma_index])
            y = str(insides[comma_index+1:])
            return (x,y)

    def feed_back_message(self):
        if self.is_correct == True:
            return "Good job! You got the correct answer."
        elif self.is_correct == False:
            return "Sorry, the correct answer is " + self.current_data[4] + "."
        else:
            return "This function needs input of True or False."

    def transition(self):
        print("Your next task starts in", end=" ")
        print("")
        for i in range(10):
            print(str(10-i))
            time.sleep(0.2)
        print("Go!")
        time.sleep(1)

    def end_message(self):
        print("Your final score is " + str(self.score) + " out of 10.")
        print("""
                Thank you for learning with the Coordinate Plane Activity.
                If it is too easy, choose a higher difficulty or speed next time.
                Have a great day!
                """)

class Coordinateplanegame:
    """This class manages the flow of the activity."""

    def __init__(self):
        self.gamedata = Game_data()
        self.gamemap = Map()
        self.ui = User_interface()
        self.finished = False
        self.task_num = 0


    def new_task(self):

        self.gamedata.data_generator(self.ui.difficulty)
        self.gamemap.plane_dict[self.gamedata.current_data[1]] = Map_object("avatar")

        if self.gamedata.current_data[0] == 1:
            self.gamemap.plane_dict[self.gamedata.current_data[2]] = Map_object("target")
        elif self.gamedata.current_data[0] == 2:
            self.gamemap.plane_dict[self.gamedata.current_data[2]] = Map_object("dog")
        elif self.gamedata.current_data[0] == 3:
            self.gamemap.plane_dict[self.gamedata.current_data[2]] = Map_object("poop")

    def answer_to_task(self):

        if self.ui.last_input == str(self.gamedata.current_data[4]) and self.ui.on_time == True:
            self.gamemap.plane_dict[self.gamedata.current_data[2]] = Map_object("win")
            self.ui.score += 1
            self.ui.is_correct = True
        else:
            self.gamemap.plane_dict[self.gamedata.current_data[1]] = Map_object("lose")
            self.ui.is_correct = False

    def game(self):

        self.ui.start_menu()

        os.system('cls||clear')

        while not self.finished:

            self.ui.transition()

            self.task_num += 1

            self.new_task()

            os.system('cls||clear')

            print(self.gamemap)

            print("Your task => " + self.gamedata.current_data[3])

            self.ui.timed_input()

            os.system('cls||clear')

            self.answer_to_task()

            print(self.gamemap)

            self.ui.feedback_message()

            print("The correct answer is " + str(self.gamedata.current_data[4]))

            stopper = input("Press enter here when you are ready to continue: ")

            self.gamemap.clear_map()

            if self.task_num == 2:
                self.finished = True

            os.system('cls||clear')

        time.sleep(1)

        os.system('cls||clear')

        time.sleep(1)

        self.ui.end_message()

gametest = Coordinateplanegame()

gametest.game()
