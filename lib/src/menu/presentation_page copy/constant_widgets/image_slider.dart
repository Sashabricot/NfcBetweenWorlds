import 'package:flutter/material.dart';

class ImageSlider extends StatefulWidget {
  const ImageSlider({super.key, required this.images});

  final List<String> images;

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: MediaQuery.of(context).size.width * 0.8,
      width: MediaQuery.of(context).size.width * 0.8,

      child: Stack(
        children: [
          SizedBox(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Image(
                  image: AssetImage(
                    'assets/images/presentation/${widget.images[index]}',
                  ),
                  filterQuality: .none,

                  fit: .contain,
                );
              },
            ),
          ),

          Column(
            children: [
              Expanded(child: SizedBox()),
              Row(
                mainAxisAlignment: .center,
                children: List.generate(widget.images.length, (index) {
                  final bool isActive = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: .symmetric(horizontal: 4),
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blue : Colors.grey.shade400,
                      borderRadius: .circular(4),
                    ),
                  );
                }),
              ),
              SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }
}
