import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'news_service.dart';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<List<dynamic>> news;

  @override
  void initState() {
    super.initState();
    news = NewsService().fetchNews();
  }

  // Function to launch the URL
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Set the AppBar to be transparent
        backgroundColor: Colors.teal,
        elevation: 0,  // Removes the shadow from the AppBar
        // Adds a back icon to navigate to the previous screen
        title: Text("News"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Pops the current screen off the stack
          },
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: news,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No news available.'));
          }

          List<dynamic> articles = snapshot.data!;
          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              var article = articles[index];
              String imageUrl = article['urlToImage'] ?? ''; // Image URL
              String articleUrl = article['url'] ?? ''; // Article URL

              return ListTile(
                contentPadding: EdgeInsets.all(10),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
                    SizedBox(height: 8),
                    Text(
                      article['title'] ?? 'No Title',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      article['description'] ?? 'No Description',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                onTap: () {
                  if (articleUrl.isNotEmpty) {
                    _launchURL(articleUrl); // Open full article
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
