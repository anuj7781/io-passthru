dev_char_str=$1;
dev_blk_str=$2;

run()
{
	local pt=$1;
	local od=$2;
	local dev_str;
	local cs;

	core_str='0';
	if [ $pt -eq 1 ]
	then
		cs=' -O0 -u1';
		of='pt';
		dev_str=$dev_char_str;
	else
		cs=' -O1';
		of='blk';
		dev_str=$dev_blk_str;
	fi

	printf "Test: ${dev_str} on cpu ${core_str}\n"

	kstr="taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p0 -F1 -B0 -P0 $cs -n1 $dev_str"
	echo $kstr
	if [ $pt -eq 1 ]
	then
		printf "For ${dev_str} char device\n" > ${od}/$of
	else
		printf "For ${dev_str} block device \n" > ${od}/$of
	fi

	printf "\nconfig = plain\n" >> ${od}/$of

	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p0 -F1 -B0 -P0 $cs -n1 $dev_str >> ${od}/$of

	printf "\nconfig = plain + fb\n" >>  ${od}/$of

	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p0 -F1 -B1 -P0 $cs -n1 $dev_str >> ${od}/$of

	printf "\nconfig = plain + iopoll\n" >> ${od}/$of

	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p1 -F1 -B0 -P0 $cs -n1 $dev_str >> ${od}/$of

	printf "\nconfig = plain + iopoll + fb\n" >> ${od}/$of

	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p1 -F1 -B1 -P0 $cs -n1 $dev_str >> ${od}/$of
}

outdir=out-$(date +"%d-%m-%Y-%H-%M-%S")
mkdir $outdir
echo "output will be inside the dir $outdir"

#passthru test
echo "running passthru test on $i device(s)"
run 1 $outdir

#block test
echo "running block test on $i device(s)"
run 0 $outdir
