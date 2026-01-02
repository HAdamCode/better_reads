import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';

class BookListTile extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final String? subtitle;
  final Widget? trailing;

  const BookListTile({
    super.key,
    required this.book,
    this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Hero(
        tag: 'book-${book.isbn}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: _buildCover(),
        ),
      ),
      title: Text(
        book.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            subtitle ?? book.authorsString,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (book.averageRating != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.star,
                  size: 14,
                  color: Colors.amber.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  book.averageRating!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (book.publishedDate != null) ...[
                  Text(
                    ' · ${book.publishedDate}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ] else if (book.publishedDate != null) ...[
            const SizedBox(height: 4),
            Text(
              book.publishedDate!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
      trailing: trailing,
    );
  }

  Widget _buildCover() {
    const width = 50.0;
    const height = 75.0;

    if (book.coverUrl == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.book, size: 24, color: Colors.grey.shade500),
      );
    }

    return CachedNetworkImage(
      imageUrl: book.coverUrlSmall,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        child: Icon(Icons.book, size: 24, color: Colors.grey.shade500),
      ),
    );
  }
}
