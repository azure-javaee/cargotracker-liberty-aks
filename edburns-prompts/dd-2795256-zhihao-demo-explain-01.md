# Prompt

Now I need to explain how the codebase uses AI to present during my talk at JavaLand 2026. I have added the original codebase that Zhihao hacked upon to add AI to this VS Code workspace as `2026-javaland-cargotracker-00-upstream-master`. This codebase is also added as a git worktree.

Given that the hacked upon workspace was presented during a session with this abstract

   Transform your legacy Java apps into AI-powered systems without starting from scratch. From CRUD to Cognitive is your guide to a smarter, AI-driven future for enterprise apps! Join Ed Burns (Principal Architect for Java on Azure) to learn how to bring intelligence into traditional Java applications. Tasked with a "do something with AI" mandate? This session shows Java enthusiasts how to embed powerful GenAI capabilities into your apps. Using open-source frameworks and models, you'll learn to enhance workflows with Retrieval-Augmented Generation (RAG), implement AI tools like form auto-fillers, streamline operations with smart chatbots, and optimize workflows with AI triggers—all without ripping apart your existing systems.
   
Analyze the abstract. Compare the unmodified code at `2026-javaland-cargotracker-00-upstream-master` with the one in `cargotracker-liberty-akv` and create a document at `edburns-prompts/20260305-explain-what-changed.md` that I can use to create slides that explain what Zhihao did. 

✅ Focus on how Zhihao AI enabled the app.

   - Libraries used.
   
   - Frameworks used.
   
   - Technologies used.
   
✅ Explain why one would choose these technologies.

   - Why were they a good choice?
   
   - What other technologies could have been used instead?
   
   - What problems might the use of this technology pose in the future?
   
- Was there really any workflow changes done?

Create an ASCII data flow diagram at `edburns-prompts/20260305-data-flows.md` that shows how the shortest path rest endpoint works. Include all parties as boxes: liberty, remote models. Include the java classes in the liberty box.
