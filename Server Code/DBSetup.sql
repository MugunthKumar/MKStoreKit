-- phpMyAdmin SQL Dump
-- version 2.11.9.5
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Nov 15, 2009 at 08:38 AM
-- Server version: .81
-- PHP Version: 5.2.9

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `mugunth1_udid`
--

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE IF NOT EXISTS `products` (
  `productid` varchar(255) NOT NULL,
  `productName` varchar(30) NOT NULL,
  `productDesc` varchar(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `requests`
--

CREATE TABLE IF NOT EXISTS `requests` (
  `udid` varchar(40) NOT NULL,
  `productid` varchar(100) NOT NULL,
  `email` varchar(100) default NULL,
  `message` varchar(1000) default NULL,
  `status` tinyint(1) NOT NULL default '0',
  `lastUpdated` timestamp NOT NULL default CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
