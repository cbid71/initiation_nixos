#!/usr/bin/env python3
import tkinter as tk

counter = 0

def click():
    global counter
    counter += 1
    btn.config(text=f"Cliqué {counter} fois !")

root = tk.Tk()
root.title("Hello NixOS")
root.geometry("300x150")
root.resizable(False, False)

lbl = tk.Label(root, text="Bienvenue sur NixOS 🐧", font=("sans", 14))
lbl.pack(pady=24)

btn = tk.Button(root, text="Clique-moi !", command=click, font=("sans", 11))
btn.pack()

root.mainloop()
