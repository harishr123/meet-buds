MeetingBuddies READme

    Features

        Sign Up / Login: Users can create an account and log in securely using their email and password via Firebase Auth.  

        Post Feed: A live timeline that updates automatically whenever someone adds a new post or likes an existing post.

        Create Posts: You can type out a post and add an optional location tag.  

        Likes: Users can toggle likes on posts, and it updates the total counter instantly.  

        Delete: If you are the owner of a post, a menu appears letting you delete it from the app and the database.  

    Files in this Project
        
        main.dart: The starting point of the app. It initializes Firebase and opens up the login screen first.  

        auth_service.dart: Handles communication to Firebase to log users in, sign them up, or log them out.  

        login_screen.dart & signup_screen.dart: The UI screens with text boxes for user emails and passwords so they can access the app.  

        feed_screen.dart: Fetches all the posts from Firestore in real-time and list them out.  

        create_post_screen.dart: The page where you type your message, add an optional location, and hit "Post" to send it to the backend.  

        post_card.dart: The UI design for a single post layout. It displays the username, time passed, text, images, location, and the like/delete buttons.  

        post_model.dart: A class that turns Firestore database data into a Dart object.  
        
        post_service.dart: Handles the backend code for posts.  

    How to Get it Running
    
        Make sure you have Flutter installed on your computer.
        Clone this project folder.
        Connect your phone or open an emulator and run flutter run.  

