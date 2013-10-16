# WHAT?

So this is a dump of the basic workflow scripts that I keep for the day
job. Mostly posted here so my co-workers can share in the fun. 

To make this make sense here's my basic workflow for projects or cases
where I am dealing with code: 


  1. student hands in project
  2. copy code to paste buffer (I'm running linux so I just select the code)
    * important thing here is as you are copying the code, glance over
      it. Does it look right? Are there common issues? Should this work?
  3. change to running terminal in the correct directory for the class
  4. > lstud
    * if you take a look at lstud for each of the lessons they each do
      basicly the same thing: pull from pastebin to some file, run the
      code. For perl and python there are some extra steps where it
      tries to work out what lesson (py) or has modes (perl) in an
      effort to automate common steps based on common issues or patterns
      that I have with a specific lesson.
  5. if the code looks great (#2) and works as expected (#4) congrats,
    grade and move on. Likewise if the code has a common error (#2) and
    breaks in the expected way, grade with a common reply and move on.
  6. ... but if there is an issue and you need to open up the file that
    is where v comes in to play. As lstud always dumps to the same file
    per-course (well language) then v is just a shortcut for that common
    file. I am a vim user so this kicks open vim but feel free to edit
    for your prefered editor.
    * now with the code open, see what's there. Can you explain why the
      code is broken. Remember that this is a local copy of the code so 
      feel free to edit and see if you can fix things.
    * with the code in an altered state, This is where run comes in to
      play. Again much like v this is just an alias for all the common
      things that you would need to run the common file so that it
      emulates the student's account as much as possible.
    * the hope is to work out what your response is going to be to the
      student given the state of the assignement.

